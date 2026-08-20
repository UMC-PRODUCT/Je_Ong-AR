#!/usr/bin/env python3
"""
카드 PNG 9장을 Xcode AR Resource Group(.arresourcegroup)으로 묶는다.

스키마는 문서가 아니라 actool 컴파일 결과로 확인한 것이다:

    actool 컴파일 → assetutil --info
      AssetType: "Recognition Group"  Name: TechCards
      AssetType: "Recognition Image"  Physical Size: "0.09,0.13"
                                      ColorModel: "Monochrome"  (ARKit은 흑백으로 저장)
                                      PixelWidth: 453  PixelHeight: 640  (actool이 다운샘플)

⚠️ unit은 centimeters / inches / meters 만 유효하다.
   "millimeters"를 넣으면 actool이 **에러 없이** Physical Size를 0.01,0.01로 떨어뜨린다.
   앵커가 엉뚱한 거리에 붙는데 빌드는 통과하므로 반드시 assetutil로 검증할 것.
"""

import json
import os
import shutil

CARD_W_CM = 9.0      # 90mm
CARD_H_CM = 12.7     # 127mm
GROUP = os.environ.get("GROUP_NAME", "TechCards")

SRC = os.environ.get("SRC_DIR", "../Docs/Assets/ReferenceCards/cards")
# 대상 xcassets 경로 (기본값: 인식 검증용 데모 앱)
DST = os.environ.get(
    "XCASSETS",
    "../ARCoreDemoApp/ARCoreDemoApp/Resources/Assets.xcassets",
)

INFO = {"author": "xcode", "version": 1}


def write_json(path, obj):
    with open(path, "w", encoding="utf-8") as fp:
        json.dump(obj, fp, indent=2)
        fp.write("\n")


def main():
    with open(os.path.join(SRC, "cards.json"), encoding="utf-8") as fp:
        cards = json.load(fp)

    group_dir = os.path.join(DST, f"{GROUP}.arresourcegroup")
    if os.path.isdir(group_dir):
        shutil.rmtree(group_dir)        # 이름이 바뀐 카드가 남지 않게 통째로 다시 만든다
    os.makedirs(group_dir)
    write_json(os.path.join(group_dir, "Contents.json"), {"info": INFO})

    for c in cards:
        name = c["referenceImageName"]
        src_png = os.path.join(SRC, f"{c['id']}.png")
        if not os.path.isfile(src_png):
            raise SystemExit(f"카드 이미지가 없다: {src_png}")

        img_dir = os.path.join(group_dir, f"{name}.arreferenceimage")
        os.makedirs(img_dir)
        shutil.copy2(src_png, os.path.join(img_dir, f"{name}.png"))
        write_json(os.path.join(img_dir, "Contents.json"), {
            "images": [{"filename": f"{name}.png", "idiom": "universal"}],
            "info": INFO,
            "properties": {
                "width": CARD_W_CM,
                "height": CARD_H_CM,
                "unit": "centimeters",
            },
        })
        print(f"  + {name}.arreferenceimage  ({CARD_W_CM} x {CARD_H_CM} cm)")

    print(f"\n  {len(cards)}장 → {group_dir}")
    print("  검증: Tools/verify_ar_resource_group.sh")


if __name__ == "__main__":
    main()
