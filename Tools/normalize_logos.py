#!/usr/bin/env python3
"""
제공받은 Apple 기술 아이콘을 카드/패널에 쓸 수 있게 정규화한다.

하는 일:
  1. 모서리가 불투명한 이미지(스크린샷으로 잡혀 배경이 박힌 것)는 모서리에서
     플러드 필로 배경을 벗겨 투명으로 만든다.
  2. 알파 bbox로 잘라내 여백을 없앤다.
  3. 정사각 캔버스에 중앙 배치해 크기를 통일한다 — 카드마다 로고 크기가 들쭉날쭉하면
     인쇄물 인상이 흐트러진다.

입력 파일명이 카드 id와 다르므로 여기서 매핑한다.
"""

import os
from collections import deque

from PIL import Image

SRC = os.environ.get("LOGO_SRC", "/Users/one/Downloads/UMC Capture")
DST = os.environ.get(
    "LOGO_DST",
    os.path.join(os.path.dirname(os.path.abspath(__file__)),
                 "..", "Docs", "Assets", "ReferenceCards", "logos"),
)

SIZE = 512          # 출력 정사각 크기
TOLERANCE = 26      # 배경 색 허용 오차 (채널당)

# 받은 파일명 → 카드 id

# 아이콘 본체 밖으로 흰 선/날개가 뻗어 있어 배경과 같은 색이라 플러드 필이 못 닿는 경우.
# 채도가 있는 영역(= 아이콘 본체)으로 잘라낸다.
# siri·apple-intelligence는 흰 배경이 아이콘 디자인 자체라 여기 넣으면 안 된다.
CROP_TO_SATURATED = {"foundation-models"}

MAPPING = {
    "Core Location.png":       "corelocation",
    "apple Intelligence.png":  "apple-intelligence",
    "cloud.png":               "cloudkit",
    "CoreML.png":              "coreml",
    "FoundationModel.png":     "foundation-models",
    "iOS26.webp":              "liquid-glass",
    "siri.png":                "sirikit",
    "UWB.png":                 "nearby-interaction",
    "widget.webp":             "widgetkit",
}


def strip_background(img):
    """모서리에서 시작하는 플러드 필로 배경을 벗긴다. 로고 내부의 같은 색은 건드리지 않는다."""
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()

    corners = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]
    if sum(1 for c in corners if px[c][3] > 200) < 3:
        return img, False          # 이미 투명 배경

    bg = px[(0, 0)][:3]
    seen = bytearray(w * h)
    q = deque(corners)

    def matches(c):
        return all(abs(c[i] - bg[i]) <= TOLERANCE for i in range(3))

    while q:
        x, y = q.popleft()
        i = y * w + x
        if seen[i]:
            continue
        seen[i] = 1
        r, g, b, a = px[x, y]
        if a == 0:
            continue
        if not matches((r, g, b)):
            continue
        px[x, y] = (r, g, b, 0)
        if x > 0: q.append((x - 1, y))
        if x < w - 1: q.append((x + 1, y))
        if y > 0: q.append((x, y - 1))
        if y < h - 1: q.append((x, y + 1))

    return img, True


def saturated_bbox(img, min_sat=60, min_alpha=120):
    """채도가 있는 픽셀만의 경계. 흰/회색 장식을 떼어내고 아이콘 본체만 남긴다."""
    px = img.load()
    w, h = img.size
    x0, y0, x1, y1 = w, h, 0, 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < min_alpha:
                continue
            if max(r, g, b) - min(r, g, b) < min_sat:
                continue
            x0 = min(x0, x); y0 = min(y0, y)
            x1 = max(x1, x); y1 = max(y1, y)
    if x1 <= x0 or y1 <= y0:
        return (0, 0, w, h)
    return (x0, y0, x1 + 1, y1 + 1)


def main():
    os.makedirs(DST, exist_ok=True)
    missing = []
    for src_name, card_id in MAPPING.items():
        path = os.path.join(SRC, src_name)
        if not os.path.isfile(path):
            missing.append(src_name)
            continue

        img = Image.open(path)
        img, stripped = strip_background(img)

        if card_id in CROP_TO_SATURATED:
            img = img.crop(saturated_bbox(img))

        bbox = img.split()[-1].getbbox()
        if bbox:
            img = img.crop(bbox)

        # 정사각 캔버스에 긴 변 기준으로 맞춰 중앙 배치
        side = max(img.size)
        canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        canvas.paste(img, ((side - img.width) // 2, (side - img.height) // 2))
        canvas = canvas.resize((SIZE, SIZE), Image.LANCZOS)

        out = os.path.join(DST, f"{card_id}.png")
        canvas.save(out)
        note = "배경 제거" if stripped else "원본 투명"
        print(f"  {card_id:<20} ← {src_name:<24} {note}")

    if missing:
        raise SystemExit("\n  원본을 못 찾음: " + ", ".join(missing))
    print(f"\n  {len(MAPPING)}개 → {DST}")


if __name__ == "__main__":
    main()
