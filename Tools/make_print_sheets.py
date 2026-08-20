#!/usr/bin/env python3
"""9장을 A4 인쇄 시트로 배치한다. A6 = A4의 1/4이므로 장당 4개, 총 3장."""

import os
from PIL import Image, ImageDraw

DPI = 300
A4 = (int(210 / 25.4 * DPI), int(297 / 25.4 * DPI))   # 2480 x 3508
CARD_MM = (90.0, 127.0)
CARD = (int(CARD_MM[0] / 25.4 * DPI), int(CARD_MM[1] / 25.4 * DPI))   # 1062 x 1500

SRC = os.environ.get("SRC_DIR", "./out")
DST = os.environ.get("DST_DIR", "./out")

IDS = ["corelocation", "apple-intelligence", "cloudkit", "coreml",
       "foundation-models", "liquid-glass", "sirikit", "nearby-interaction",
       "widgetkit"]

# A4 세로에 90x127 카드 4장: 2열 x 2행. 180x254mm를 쓰고 나머지가 여백/재단선이 된다.
# 축소하지 않는다 — 인쇄물이 곧 Xcode에 입력할 실측 크기여야 한다.
CW, CH = CARD
MX = (A4[0] - CW * 2) // 3          # 좌우 여백/간격
MY = (A4[1] - CH * 2) // 3


def crop_marks(d, x, y, w, h):
    """재단선. 카드 밖으로 뻗는 짧은 선 — 카드 안을 침범하지 않는다."""
    L = 34
    for (cx, cy, dx, dy) in ((x, y, -1, -1), (x + w, y, 1, -1),
                             (x, y + h, -1, 1), (x + w, y + h, 1, 1)):
        d.line([(cx + dx * 6, cy), (cx + dx * L, cy)], fill=(120, 120, 120), width=3)
        d.line([(cx, cy + dy * 6), (cx, cy + dy * L)], fill=(120, 120, 120), width=3)


def main():
    os.makedirs(DST, exist_ok=True)
    sheets = [IDS[i:i + 4] for i in range(0, len(IDS), 4)]
    for si, group in enumerate(sheets, start=1):
        sheet = Image.new("RGB", A4, (255, 255, 255))
        d = ImageDraw.Draw(sheet)
        for i, cid in enumerate(group):
            col, row = i % 2, i // 2
            x = MX + col * (CW + MX)
            y = MY + row * (CH + MY)
            card = Image.open(os.path.join(SRC, f"{cid}.png")).resize((CW, CH), Image.LANCZOS)
            sheet.paste(card, (x, y))
            crop_marks(d, x, y, CW, CH)
        d.text((MX, A4[1] - MY // 2),
               f"Jeong-AR reference cards  sheet {si}/{len(sheets)}   "
               f"print at 100% (no scaling), matte paper   "
               f"card = {CARD_MM[0]:.0f} x {CARD_MM[1]:.0f} mm",
               fill=(110, 110, 110))
        p = os.path.join(DST, f"_print_sheet_{si}.png")
        sheet.save(p, dpi=(DPI, DPI))
        print(f"  sheet {si}: {', '.join(group)}")

    # 실제 인쇄 크기 안내
    print(f"\n  카드 실측 크기: {CARD_MM[0]:.0f} x {CARD_MM[1]:.0f} mm "
          f"(Xcode AR Resource Group에 이 값을 그대로 입력한다)")


if __name__ == "__main__":
    main()
