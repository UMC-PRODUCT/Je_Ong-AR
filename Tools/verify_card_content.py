#!/usr/bin/env python3
"""
TechCard.all(Swift)과 cards.json이 글자 그대로 같은지 대조한다.

DESIGN.md §6이 감수하기로 한 이중화의 안전망이다. 원본은
gen_reference_cards.py의 CARDS이고 cards.json이 거기서 생성되며,
TechCard.swift는 그 사본이다. 어긋나면 카드 뒷면과 AR 패널 내용이 따로 논다.

유닛 테스트로는 못 잡는다 — 앱이 JSON을 읽지 않기 때문이다.
콘텐츠를 고쳤으면 이걸 돌릴 것.
"""

import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SWIFT = os.path.join(HERE, "..", "UMCAR", "ARCore", "Sources", "Data", "TechCard.swift")
JSON = os.path.join(HERE, "..", "Docs", "Assets", "ReferenceCards", "cards", "cards.json")

FIELDS = ("id", "name", "tag", "summary", "detail")


def swift_string(raw):
    """여러 줄로 쪼개져 + 로 이어진 Swift 문자열 리터럴을 하나로 합친다."""
    parts = re.findall(r'"((?:[^"\\]|\\.)*)"', raw)
    return "".join(parts).replace('\\"', '"')


def parse_swift():
    src = open(SWIFT, encoding="utf-8").read()
    body = src.split("static let all: [TechCard] = [", 1)[1]
    cards = []
    # .init( ... ) 블록 단위로 자른다
    for block in re.findall(r"\.init\((.*?)\n        \)", body, re.S):
        card = {}
        for field in FIELDS:
            m = re.search(rf"\b{field}:\s*((?:\s*\"(?:[^\"\\]|\\.)*\"\s*\+?)+)", block)
            if not m:
                raise SystemExit(f"Swift에서 {field}를 못 찾음:\n{block[:200]}")
            card[field] = swift_string(m.group(1))
        cards.append(card)
    return cards


def main():
    swift_cards = parse_swift()
    json_cards = json.load(open(JSON, encoding="utf-8"))

    problems = []
    if len(swift_cards) != len(json_cards):
        problems.append(f"장수 불일치: Swift {len(swift_cards)} vs JSON {len(json_cards)}")

    by_id = {c["id"]: c for c in json_cards}
    for sc in swift_cards:
        jc = by_id.get(sc["id"])
        if jc is None:
            problems.append(f"{sc['id']}: JSON에 없는 카드")
            continue
        for field in FIELDS:
            if sc[field] != jc[field]:
                problems.append(
                    f"{sc['id']}.{field} 불일치\n"
                    f"    Swift: {sc[field][:70]}\n"
                    f"    JSON : {jc[field][:70]}"
                )

    for sid in set(by_id) - {c["id"] for c in swift_cards}:
        problems.append(f"{sid}: Swift에 없는 카드")

    if problems:
        print("FAIL")
        for p in problems:
            print("  " + p)
        sys.exit(1)

    print(f"PASS: {len(swift_cards)}장 모두 cards.json과 일치")


if __name__ == "__main__":
    main()
