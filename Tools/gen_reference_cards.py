#!/usr/bin/env python3
"""
ARKit 레퍼런스 이미지용 카드 뒷면 9장 생성기.

설계 원칙 (ARKit 이미지 인식 요구사항에서 역산):
  1. 인식은 휘도 기반이다 → 색이 아니라 명암 구조를 9종 다르게 만든다.
  2. 특징점이 균일하게 분포해야 한다 → 국소 고주파 에너지를 실제로 측정해
     빈 영역에 디테일을 주입한다 (추측하지 않는다).
  3. 반복 패턴은 오인식을 부른다 → 카드마다 대형 비대칭 구성 레이어를 깔아
     전역 구조를 유일하게 만든다. 지터만으로는 반복성이 안 깨진다.
  4. 회전 대칭이 있으면 방향이 흔들린다 → 비대칭 코너 웨지로 방향을 못 박는다.
  5. 큰 단색 면적 금지 → 텍스트 판은 반투명 + 최소 크기로 제한한다.

출력: 90x127mm @ 300DPI = 1062x1500px  (A4 한 장에 4장씩 100% 인쇄)
"""

import json
import math
import os
import random

from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops

# ---------------------------------------------------------------- 설정

MM_W, MM_H = 90.0, 127.0           # A4에 4장 + 여백. A계열 비율 유지
DPI = 300
SS = 2                              # 슈퍼샘플링 배수

W = int(MM_W / 25.4 * DPI)          # 1062
H = int(MM_H / 25.4 * DPI)          # 1500
CW, CH = W * SS, H * SS

FONT_BLACK = "/System/Library/Fonts/Supplemental/Arial Black.ttf"
# 한글 태그용. 프로젝트가 이미 쓰는 폰트라 부스 인쇄물과 앱 UI의 인상이 어긋나지 않는다.
FONT_KR = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "..", "UMCAR", "UMCAR", "Resources", "Font", "NPSfont_extrabold.ttf")

OUT = os.environ.get("OUT_DIR", "./out")
# 정규화된 Apple 기술 아이콘. Tools/normalize_logos.py 가 만든다.
LOGO_DIR = os.environ.get("LOGO_DIR", os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..",
    "Docs", "Assets", "ReferenceCards", "logos"))

# 특징 밀도 점검 격자. 셀 하나가 대략 7x7mm.
GW, GH = 13, 18
# 셀당 최소 고주파 에너지 (최종 출력 스케일 기준).
# 이 아래는 "특징점이 부족한 영역"으로 보고 디테일을 주입한다.
# 주입 OFF 상태의 실측 분포(중앙값 19, 하위5% 2)에서 역산한 값.
# 중앙값의 절반. 진짜 공백만 메우고 패턴 정체성은 남긴다.
MIN_EDGE = 10.0

# 텍스트 판 영역 (비율). 주입 레이어는 이 안을 건드리지 않는다 — 가독성 보호.
PLATE = (0.07, 0.375, 0.93, 0.575)

# 카드 스타일.
#   "icon"    — 아이콘이 주역 (기본). 배경 패턴은 인식용으로 남긴다
#   "pattern" — 패턴이 주역, 로고는 판 안쪽 작게. 되돌릴 때 CARD_STYLE=pattern
STYLE = os.environ.get("CARD_STYLE", "icon")

# 패턴 대비를 얼마나 누를지. icon 스타일에서 배경을 "거의 단색처럼" 보이게 한다.
# 0에 가까울수록 눈에 안 띄지만 ARKit이 쓸 휘도 진폭도 같이 줄어든다.
TONE_SCALE = 1.0

# 로고 한 변 (카드 높이 대비). 텍스트 줄 수에 묶으면 두 줄짜리 이름만 로고가 커져
# 9장의 인상이 흐트러진다. 고정값으로 통일한다.
LOGO_FRAC = 0.065


def font(path, size):
    return ImageFont.truetype(path, size)


def tone(base, delta):
    """base RGB에 명도 델타를 더한다. 휘도 다양성을 만드는 핵심.

    TONE_SCALE로 진폭을 누른다. icon 스타일은 배경이 눈에 띄면 안 되지만
    ARKit이 쓸 고주파는 남아 있어야 해서, 진폭만 줄이고 구조는 그대로 둔다."""
    return tuple(max(0, min(255, int(c + delta * TONE_SCALE))) for c in base)


# ---------------------------------------------------------------- 대형 구성 레이어
# 반복 패턴 경고를 막는 장치. 카드마다 전역 명암 구성이 유일해진다.

def composition_layer(d, rng, ink, bg):
    """비대칭 대형 다각형 4~6개. 저주파 구조를 카드마다 다르게 만든다."""
    n = rng.randint(4, 6)
    for _ in range(n):
        cx = rng.uniform(-CW * 0.2, CW * 1.2)
        cy = rng.uniform(-CH * 0.15, CH * 1.15)
        r = rng.uniform(CW * 0.28, CW * 0.85)
        verts = rng.randint(3, 5)
        rot = rng.uniform(0, 360)
        pts = []
        for i in range(verts):
            th = math.radians(rot + i * (360 / verts) + rng.uniform(-28, 28))
            rr = r * rng.uniform(0.55, 1.0)
            pts.append((cx + rr * math.cos(th), cy + rr * math.sin(th)))
        # 배경과 잉크 사이의 중간 톤들 — 휘도 계조를 넓힌다
        t = rng.uniform(0.18, 0.82)
        col = tuple(int(bg[i] + (ink[i] - bg[i]) * t) for i in range(3))
        d.polygon(pts, fill=tone(col, rng.uniform(-22, 22)))


# ---------------------------------------------------------------- 패턴 9종
# 각 함수는 명암 구조가 서로 다른 계열을 그린다.

def pat_diagonal_bands(d, rng, ink, bg):
    """1. 사선 밴드 + 밴드 내부 잔선. 강한 방향성."""
    ang = math.radians(27)
    step = CW // 26
    span = int(math.hypot(CW, CH))
    for i in range(-span // step, span // step + 1):
        off = i * step + rng.randint(-step // 3, step // 3)
        wdt = rng.randint(step // 6, step // 2)
        t = rng.uniform(-70, 70)
        x0 = off * math.cos(ang) - span * math.sin(ang)
        y0 = off * math.sin(ang) + span * math.cos(ang)
        x1 = off * math.cos(ang) + span * math.sin(ang)
        y1 = off * math.sin(ang) - span * math.cos(ang)
        d.line([(x0, y0), (x1, y1)], fill=tone(ink, t), width=wdt)
        # 밴드를 무작위로 끊어 반복성을 깬다
        for _ in range(rng.randint(1, 3)):
            k0 = rng.uniform(0.05, 0.8)
            k1 = min(1.0, k0 + rng.uniform(0.06, 0.3))
            d.line([(x0 + (x1 - x0) * k0, y0 + (y1 - y0) * k0),
                    (x0 + (x1 - x0) * k1, y0 + (y1 - y0) * k1)],
                   fill=tone(bg, rng.uniform(-55, 55)), width=int(wdt * 1.1))


def pat_nested_squares(d, rng, ink, bg):
    """2. 회전 사각형 격자. 코너 특징점이 대량 발생."""
    cell = CW // 7
    for gy in range(-1, CH // cell + 2):
        for gx in range(-1, CW // cell + 2):
            cx = gx * cell + cell / 2 + rng.randint(-cell // 4, cell // 4)
            cy = gy * cell + cell / 2 + rng.randint(-cell // 4, cell // 4)
            n = rng.randint(1, 4)
            rot = rng.uniform(0, 90)
            for k in range(n):
                r = cell * rng.uniform(0.3, 0.52) * (1 - k / (n + 0.6))
                pts = []
                for a in range(4):
                    th = math.radians(rot + a * 90)
                    pts.append((cx + r * math.cos(th), cy + r * math.sin(th)))
                col = ink if k % 2 == 0 else bg
                if rng.random() < 0.25:
                    d.polygon(pts, fill=tone(col, rng.uniform(-45, 45)))
                else:
                    d.polygon(pts, outline=tone(col, rng.uniform(-45, 45)),
                              width=max(2, int(cell * 0.055)))


def pat_triangle_field(d, rng, ink, bg):
    """3. 산개 삼각형. 다중 스케일, 무방향."""
    for _ in range(380):
        cx, cy = rng.uniform(0, CW), rng.uniform(0, CH)
        r = rng.uniform(CW * 0.012, CW * 0.075)
        rot = rng.uniform(0, 360)
        pts = []
        for a in range(3):
            th = math.radians(rot + a * 120)
            pts.append((cx + r * math.cos(th), cy + r * math.sin(th)))
        col = tone(ink if rng.random() < 0.6 else bg, rng.uniform(-60, 60))
        if rng.random() < 0.5:
            d.polygon(pts, fill=col)
        else:
            d.polygon(pts, outline=col, width=max(2, int(r * 0.16)))


def pat_offcenter_arcs(d, rng, ink, bg):
    """4. 편심 동심호 + 이심 보조호. 곡률 변화가 큰 특징."""
    for ox, oy, spread in ((CW * 0.32, CH * 0.61, 1.0), (CW * 0.86, CH * 0.14, 0.55)):
        r = CW * 0.04
        while r < CW * 1.5 * spread + CW * 0.3:
            wdt = rng.randint(int(CW * 0.006), int(CW * 0.026))
            start = rng.uniform(0, 360)
            for _ in range(rng.randint(2, 5)):
                ext = rng.uniform(22, 95)
                d.arc([ox - r, oy - r, ox + r, oy + r], start, start + ext,
                      fill=tone(ink, rng.uniform(-60, 60)), width=wdt)
                start += ext + rng.uniform(12, 55)
            r *= rng.uniform(1.09, 1.2)


def pat_mosaic_bricks(d, rng, ink, bg):
    """5. 어긋난 벽돌 모자이크. 수평 엣지가 조밀."""
    rows = 28
    rh = CH / rows
    for i in range(rows):
        y = i * rh
        x = -rng.uniform(0, CW * 0.25)
        while x < CW:
            bw = rng.uniform(CW * 0.04, CW * 0.2)
            g = rng.uniform(-80, 80)
            d.rectangle([x, y, x + bw - CW * 0.006, y + rh - CH * 0.004],
                        fill=tone(ink if rng.random() < 0.55 else bg, g))
            x += bw


def pat_node_graph(d, rng, ink, bg):
    """6. 노드-엣지 그래프. 점 특징 + 선 교차."""
    nodes = [(rng.uniform(CW * 0.03, CW * 0.97), rng.uniform(CH * 0.02, CH * 0.98))
             for _ in range(96)]
    for i, (x0, y0) in enumerate(nodes):
        ds = sorted(range(len(nodes)),
                    key=lambda j: (nodes[j][0] - x0) ** 2 + (nodes[j][1] - y0) ** 2)
        for j in ds[1:rng.randint(3, 6)]:
            x1, y1 = nodes[j]
            d.line([(x0, y0), (x1, y1)], fill=tone(ink, rng.uniform(-55, 55)),
                   width=max(2, int(CW * 0.0045)))
    for (x, y) in nodes:
        r = rng.uniform(CW * 0.008, CW * 0.03)
        col = tone(ink if rng.random() < 0.5 else bg, rng.uniform(-60, 60))
        d.ellipse([x - r, y - r, x + r, y + r], fill=col)


def pat_chevron_shards(d, rng, ink, bg):
    """7. 각진 셰브론 파편. 예각 코너가 많다."""
    for _ in range(210):
        cx, cy = rng.uniform(0, CW), rng.uniform(0, CH)
        L = rng.uniform(CW * 0.04, CW * 0.2)
        th = rng.uniform(0, 360)
        spread = rng.uniform(25, 78)
        wdt = max(3, int(rng.uniform(CW * 0.005, CW * 0.021)))
        a1 = math.radians(th - spread)
        a2 = math.radians(th + spread)
        d.line([(cx + L * math.cos(a1), cy + L * math.sin(a1)), (cx, cy),
                (cx + L * math.cos(a2), cy + L * math.sin(a2))],
               fill=tone(ink if rng.random() < 0.6 else bg, rng.uniform(-60, 60)),
               width=wdt, joint="curve")


def pat_radial_rays(d, rng, ink, bg):
    """8. 편심 방사선 + 링. 링을 조각내 반복성을 깬다."""
    ox, oy = CW * 0.71, CH * 0.34
    n = 44
    a = rng.uniform(0, 360)
    for _ in range(n):
        a += 360 / n + rng.uniform(-7, 7)
        th = math.radians(a)
        L0 = rng.uniform(0, CW * 0.25)
        L = rng.uniform(CW * 0.4, CW * 1.6)
        wdt = max(3, int(rng.uniform(CW * 0.004, CW * 0.02)))
        d.line([(ox + L0 * math.cos(th), oy + L0 * math.sin(th)),
                (ox + L * math.cos(th), oy + L * math.sin(th))],
               fill=tone(ink, rng.uniform(-60, 60)), width=wdt)
    r = CW * 0.06
    while r < CW * 1.2:
        start = rng.uniform(0, 360)
        for _ in range(rng.randint(2, 4)):
            ext = rng.uniform(35, 120)
            d.arc([ox - r, oy - r, ox + r, oy + r], start, start + ext,
                  fill=tone(bg, rng.uniform(-55, 55)), width=max(3, int(CW * 0.009)))
            start += ext + rng.uniform(18, 70)
        r *= rng.uniform(1.17, 1.35)


def pat_corner_ells(d, rng, ink, bg):
    """9. L자 코너 조각. 직각 코너 특징이 균일하게 깔린다."""
    cell = CW // 9
    for gy in range(-1, CH // cell + 2):
        for gx in range(-1, CW // cell + 2):
            cx = gx * cell + rng.uniform(0, cell * 0.5)
            cy = gy * cell + rng.uniform(0, cell * 0.5)
            s = cell * rng.uniform(0.4, 1.0)
            wdt = max(3, int(cell * rng.uniform(0.1, 0.24)))
            rot = rng.choice([0, 90, 180, 270])
            pts = [(0, s), (0, 0), (s, 0)]
            rad = math.radians(rot)
            rp = [(cx + px * math.cos(rad) - py * math.sin(rad),
                   cy + px * math.sin(rad) + py * math.cos(rad)) for px, py in pts]
            d.line(rp, fill=tone(ink if rng.random() < 0.6 else bg, rng.uniform(-60, 60)),
                   width=wdt, joint="curve")


PATTERNS = [pat_diagonal_bands, pat_nested_squares, pat_triangle_field,
            pat_offcenter_arcs, pat_mosaic_bricks, pat_node_graph,
            pat_chevron_shards, pat_radial_rays, pat_corner_ells]


# ---------------------------------------------------------------- 카드 정의
# bg/ink는 휘도가 서로 다르게 배치한다 (밝은바탕-어두운잉크 / 그 반대를 섞는다).

CARDS = [
    {
        "id": "corelocation", "name": "CoreLocation", "tag": "위치·방향",
        "summary": "기기가 지금 어디 있는지 알려주는 프레임워크",
        "detail": "GPS·Wi-Fi·셀룰러·기압계를 조합해 위·경도, 고도, 나침반 방위를 제공한다. "
                  "특정 구역 진입/이탈 감지(지오펜싱)와 iBeacon도 여기에 포함된다.",
        "pattern": 7,   # 편심 방사선 — 신호가 퍼지는 측위의 인상
        "bg": (240, 241, 243), "ink": (28, 34, 44),
    },
    {
        "id": "apple-intelligence", "name": "Apple Intelligence", "tag": "온디바이스 개인 지능",
        "summary": "기기 안에서 동작하는 Apple의 AI 시스템",
        "detail": "글쓰기 도구, Genmoji, 알림 요약, Siri를 하나로 묶는다. 대부분 기기 안에서 "
                  "처리하고, 큰 연산만 Private Cloud Compute로 넘겨 프라이버시를 지킨다.",
        "pattern": 5,   # 노드-엣지 그래프 — 신경망
        "bg": (24, 30, 42), "ink": (218, 226, 236),
    },
    {
        "id": "cloudkit", "name": "CloudKit", "tag": "iCloud 동기화",
        "summary": "서버를 만들지 않고 데이터를 기기 간에 동기화",
        "detail": "사용자의 iCloud 계정에 데이터를 저장해 아이폰·아이패드·맥이 같은 내용을 "
                  "보게 한다. 비공개·공유·공개 3가지 저장소를 제공한다.",
        "pattern": 3,   # 편심 동심호 — 순환하는 동기화
        "bg": (234, 228, 216), "ink": (48, 40, 30),
    },
    {
        "id": "coreml", "name": "CoreML", "tag": "온디바이스 머신러닝",
        "summary": "학습된 AI 모델을 앱 안에서 직접 실행",
        "detail": "모델 파일을 Xcode에 넣으면 Swift 코드가 자동 생성된다. CPU·GPU·Neural "
                  "Engine에 연산을 알아서 나눠 서버 없이 빠르게 추론한다.",
        "pattern": 1,   # 회전 사각형 격자 — 레이어가 겹친 구조
        "bg": (188, 182, 198), "ink": (36, 32, 44),
    },
    {
        "id": "foundation-models", "name": "Foundation Models", "tag": "내장 LLM (iOS 26)",
        "summary": "Apple의 온디바이스 언어 모델을 코드로 호출",
        "detail": "Apple Intelligence의 약 30억 파라미터 모델에 직접 프롬프트를 보낸다. "
                  "오프라인·무료로 동작하고, Swift 타입을 지정하면 그 구조 그대로 결과를 받는다.",
        "pattern": 4,   # 어긋난 벽돌 — 토큰이 이어 붙는 인상
        "bg": (226, 234, 230), "ink": (30, 48, 42),
    },
    {
        "id": "liquid-glass", "name": "Liquid Glass", "tag": "iOS 26 디자인",
        "summary": "빛을 굴절시키는 유리 재질의 새 인터페이스",
        "detail": "콘텐츠 위에 떠 있는 유리 레이어가 배경을 굴절·반사하고, 스크롤과 터치에 "
                  "반응해 모양이 변한다. 툴바·탭바·시트에 자동 적용된다.",
        "pattern": 0,   # 사선 밴드 — 굴절된 빛
        "bg": (28, 40, 36), "ink": (214, 228, 220),
    },
    {
        "id": "sirikit", "name": "SiriKit", "tag": "음성·단축어 연동",
        "summary": "앱의 기능을 Siri와 단축어에 노출",
        "detail": "앱이 할 수 있는 동작을 시스템에 등록하면 음성 명령, 단축어, 잠금 화면, "
                  "액션 버튼에서 앱을 열지 않고 실행할 수 있다.",
        "pattern": 6,   # 셰브론 파편 — 음성 파형
        "bg": (242, 236, 230), "ink": (40, 30, 26),
    },
    {
        "id": "nearby-interaction", "name": "Nearby Interaction", "tag": "초광대역 정밀 측위",
        "summary": "근처 기기까지의 거리와 방향을 센티미터 단위로",
        "detail": "U1/U2 칩의 UWB 신호로 상대 기기가 얼마나 멀리, 어느 쪽에 있는지 측정한다. "
                  "AirTag 정밀 탐색이 이 기술이다.",
        "pattern": 2,   # 산개 삼각형 — 삼각측량
        "bg": (26, 32, 48), "ink": (212, 220, 236),
    },
    {
        "id": "widgetkit", "name": "WidgetKit", "tag": "위젯·라이브 액티비티",
        "summary": "앱을 열지 않고 홈 화면에서 정보를 보여주는 방법",
        "detail": "홈·잠금·대기 화면과 Watch 위젯, 실시간 진행 상황(라이브 액티비티)을 "
                  "SwiftUI로 만든다. 시스템이 미리 만든 화면을 대신 그려 배터리를 아낀다.",
        "pattern": 8,   # L자 코너 조각 — 위젯 모서리
        "bg": (198, 190, 202), "ink": (40, 30, 46),
    },
]


def fit_name(d, name, max_w, max_size):
    """
    기술명을 한 줄로 넣어보고, 그러느라 글자가 너무 작아지면 두 줄로 쪼갠다.
    'Apple Intelligence'처럼 긴 이름이 한 줄에 눌려 작아지면 부스에서 안 읽힌다.
    """
    def width_at(text, size):
        bb = d.textbbox((0, 0), text, font=font(FONT_BLACK, size))
        return bb[2] - bb[0]

    size = max_size
    while size > 12 and width_at(name, size) > max_w:
        size -= 2
    if size >= max_size * 0.62 or " " not in name:
        return [name], size

    parts = name.split(" ")
    mid = max(1, len(parts) // 2)
    lines = [" ".join(parts[:mid]), " ".join(parts[mid:])]
    size = max_size
    while size > 12 and max(width_at(l, size) for l in lines) > max_w:
        size -= 2
    return lines, size


def draw_text_plate(img, d, name, tag, bg, logo_path=None):
    """
    텍스트 판. 텍스트 폭에 맞춰 판을 줄인다.
    판이 넓으면 좌우 여백이 평평해져 특징점 공백이 생기므로, 판은 글자에 밀착시키고
    남는 폭은 패턴이 차지하게 둔다. 반환값은 실제 판 사각형 (주입 제외 영역).

    로고는 판 **안쪽 왼편**에만 놓는다. Apple 기술 아이콘은 평면 벡터라 특징점이
    빈약하므로, 크게 깔면 인식에 쓸 고주파 영역을 그만큼 잡아먹는다. 판 안은 이미
    주입 제외 영역이라 로고를 넣어도 특징 밀도가 더 나빠지지 않는다.
    """
    plate_dark = sum(bg) < 400          # 어두운 배경이면 밝은 판을 깐다
    plate_col = (250, 250, 250) if plate_dark else (16, 16, 18)
    text_col = (16, 16, 18) if plate_dark else (248, 248, 250)

    has_logo = logo_path is not None and os.path.isfile(logo_path)

    # 로고가 들어가면 글자가 쓸 수 있는 폭이 줄어든다
    avail = (PLATE[2] - PLATE[0]) * CW * 0.9
    max_w = avail * (0.74 if has_logo else 1.0)

    lines, size = fit_name(d, name, max_w, int(CH * 0.072))
    f = font(FONT_BLACK, size)

    tag_size = int(CH * 0.026)
    ft = font(FONT_KR, tag_size)

    # 높이는 가정하지 않고 실측한다. 폰트마다 글리프가 차지하는 세로 범위가 달라서
    # size 배수로 쌓으면 영문 이름과 한글 태그가 겹친다.
    name_bbs = [d.textbbox((0, 0), l, font=f) for l in lines]
    bbt = d.textbbox((0, 0), tag, font=ft)
    tag_w = bbt[2] - bbt[0]

    gap = size * 0.2
    text_h = (sum(b[3] - b[1] for b in name_bbs) + gap * (len(lines) - 1)
              + gap * 1.5 + (bbt[3] - bbt[1]))
    text_w = max(max(b[2] - b[0] for b in name_bbs), tag_w)

    logo_side = CH * LOGO_FRAC if has_logo else 0
    logo_gap = size * 0.42 if has_logo else 0

    inner_h = max(text_h, logo_side)
    inner_w = logo_side + logo_gap + text_w

    # 판을 내용에 밀착 — 여백은 글자 크기에 비례
    pad_x = size * 0.35
    pad_y = size * 0.26
    cx = CW / 2
    px0 = cx - inner_w / 2 - pad_x
    px1 = cx + inner_w / 2 + pad_x
    py0 = CH * PLATE[1]
    py1 = py0 + pad_y * 2 + inner_h

    overlay = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.rectangle([px0, py0, px1, py1], fill=plate_col + (158,))
    img.alpha_composite(overlay)

    d.rectangle([px0, py0, px1, py1], outline=text_col, width=max(3, int(CW * 0.006)))

    content_x = px0 + pad_x
    if has_logo:
        logo = Image.open(logo_path).convert("RGBA")
        side = int(round(logo_side))
        logo = logo.resize((side, side), Image.LANCZOS)
        lx = int(round(content_x))
        ly = int(round(py0 + pad_y + (inner_h - logo_side) / 2))
        img.alpha_composite(logo, (lx, ly))
        # 로고 둘레 테두리. Apple 아이콘은 평면이라 격자 셀 하나가 통째로 평평해질 수
        # 있는데, 셀을 가로지르는 엣지가 생기면 그 공백이 사라진다.
        d.rounded_rectangle(
            [lx, ly, lx + side, ly + side],
            radius=side * 0.22,
            outline=text_col,
            width=max(2, int(CW * 0.004)),
        )
        content_x += logo_side + logo_gap

    # 글자는 로고 오른쪽 블록 안에서 가운데 정렬
    text_cx = content_x + text_w / 2
    y = py0 + pad_y + (inner_h - text_h) / 2
    for l, bb in zip(lines, name_bbs):
        d.text((text_cx - (bb[2] - bb[0]) / 2 - bb[0], y - bb[1]), l, font=f, fill=text_col)
        y += (bb[3] - bb[1]) + gap
    y += gap * 0.5
    d.text((text_cx - tag_w / 2 - bbt[0], y - bbt[1]), tag, font=ft, fill=text_col)

    return (px0, py0, px1, py1)


def draw_icon_layout(img, d, card, bg, ink):
    """
    아이콘이 주역인 구성. 아이콘 / 기술명 / 태그를 세로로 쌓는다.

    배경 패턴은 TONE_SCALE로 눌러서 육안에는 거의 단색으로 보이게 하되 구조는
    남긴다 — ARKit이 쓸 고주파가 없으면 인식이 죽는다. 반환값은 주입 제외 영역.
    """
    name, tag = card["name"], card["tag"]
    logo_path = os.path.join(LOGO_DIR, f"{card['id']}.png")

    dark_bg = sum(bg) < 400
    # 판이 밝으면 글자는 어둡게. 판 색은 아래에서 dark_bg로 정한다
    text_col = (246, 247, 248) if dark_bg else (16, 18, 20)
    sub_col = (170, 176, 182) if dark_bg else (92, 98, 104)

    # 아이콘 — 카드 폭의 절반 이상. 부스에서 멀리서도 무엇인지 보이게 한다
    side = int(CW * 0.52)
    top = int(CH * 0.20)
    pad = int(CW * 0.015)
    rects = []
    if os.path.isfile(logo_path):
        logo = Image.open(logo_path).convert("RGBA").resize((side, side), Image.LANCZOS)
        lx = (CW - side) // 2
        img.alpha_composite(logo, (lx, top))
        rects.append((lx - pad, top - pad, lx + side + pad, top + side + pad))

    y = top + side + int(CH * 0.045)

    # 기술명 — 두 줄까지 허용
    lines, size = fit_name(d, name, CW * 0.84, int(CH * 0.062))
    f = font(FONT_BLACK, size)

    # 글자 뒤에만 반투명 판을 깐다. 아이콘은 자체 배경이 있어 그냥 읽히지만
    # 글자는 패턴 위에 그대로 얹으면 묻힌다.
    tag_size_pre = int(CH * 0.028)
    ft_pre = font(FONT_KR, tag_size_pre)
    name_bbs = [d.textbbox((0, 0), l, font=f) for l in lines]
    bbt_pre = d.textbbox((0, 0), tag, font=ft_pre)
    block_w = max(max(b[2] - b[0] for b in name_bbs), bbt_pre[2] - bbt_pre[0])
    block_h = (sum(b[3] - b[1] for b in name_bbs) + size * 0.18 * len(lines)
               + size * 0.12 + (bbt_pre[3] - bbt_pre[1]))
    bx = size * 0.5
    by = size * 0.34
    plate_col = (250, 250, 250) if not dark_bg else (14, 16, 18)
    overlay = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    ImageDraw.Draw(overlay).rounded_rectangle(
        [CW / 2 - block_w / 2 - bx, y - by, CW / 2 + block_w / 2 + bx, y + block_h + by],
        radius=size * 0.28, fill=plate_col + (196,))
    img.alpha_composite(overlay)

    for line in lines:
        bb = d.textbbox((0, 0), line, font=f)
        w = bb[2] - bb[0]
        d.text((CW / 2 - w / 2 - bb[0], y - bb[1]), line, font=f, fill=text_col)
        rects.append((CW / 2 - w / 2 - pad, y - pad, CW / 2 + w / 2 + pad, y + (bb[3] - bb[1]) + pad))
        y += (bb[3] - bb[1]) + size * 0.18

    # 태그
    tag_size = int(CH * 0.028)
    ft = font(FONT_KR, tag_size)
    bbt = d.textbbox((0, 0), tag, font=ft)
    y += size * 0.12
    tw = bbt[2] - bbt[0]
    d.text((CW / 2 - tw / 2 - bbt[0], y - bbt[1]), tag, font=ft, fill=sub_col)
    rects.append((CW / 2 - tw / 2 - pad, y - pad, CW / 2 + tw / 2 + pad, y + (bbt[3] - bbt[1]) + pad))

    return rects


def draw_orientation_marks(d, idx, ink, bg):
    """
    방향 고정용 비대칭 마크.
    좌상단 웨지 + 우하단 인덱스 바 → 180도 회전 모호성을 제거한다.
    카드마다 형태가 달라 상호 오인식에도 기여한다.
    """
    m = int(CW * 0.055)
    k = 1.0 + (idx % 3) * 0.45
    d.polygon([(0, 0), (m * 2.2 * k, 0), (0, m * 2.2)], fill=ink)
    d.polygon([(0, 0), (m * 1.1 * k, 0), (0, m * 1.1)], fill=bg)

    # 우하단 인덱스 바 (1~9개) — 사람이 카드를 식별할 때도 쓴다
    bw, bh = int(CW * 0.028), int(CH * 0.012)
    gap = int(bw * 0.6)
    x = CW - int(CW * 0.05)
    y = CH - int(CH * 0.045)
    for _ in range(idx + 1):
        d.rectangle([x - bw, y - bh, x, y], fill=ink)
        x -= (bw + gap)

    d.rectangle([int(CW * 0.012), int(CH * 0.009),
                 CW - int(CW * 0.012), CH - int(CH * 0.009)],
                outline=ink, width=max(3, int(CW * 0.007)))


# ---------------------------------------------------------------- 특징 밀도 측정/보정

def finalize(img):
    """최종 출력 파이프라인. 측정과 저장이 같은 이미지를 보게 하려고 분리했다."""
    out = img.convert("RGB").resize((W, H), Image.LANCZOS)
    return out.filter(ImageFilter.UnsharpMask(radius=1.6, percent=95, threshold=2))


def edge_energy_grid(img):
    """
    국소 고주파 에너지 격자. ARKit이 특징점을 뽑는 성질을 근사한다.
    원본과 가우시안 블러의 차이 = 고주파 성분. 셀 평균으로 집계한다.

    반드시 최종 출력 스케일에서 잰다. 슈퍼샘플 캔버스에서 재면 다운스케일+샤픈이
    올려줄 에너지를 못 보고 과잉 주입하게 된다.
    """
    g = (img if img.size == (W, H) else finalize(img)).convert("L")
    blur = g.filter(ImageFilter.GaussianBlur(radius=5))
    hi = ImageChops.difference(g, blur)
    cells = hi.resize((GW, GH), Image.BOX)
    return list(cells.getdata())


def inject_detail(d, rng, cells, ink, bg, plate):
    """에너지가 낮은 셀에만 고대비 마크를 주입한다. 빈 영역을 없애는 것이 목적.

    plate는 사각형 하나 또는 여러 개를 받는다. 아이콘 스타일은 아이콘과 글자에
    딱 붙은 사각형들만 제외해야 한다 — 띠 전체를 제외하면 좌우 여백까지 못 채워
    죽은 셀이 대량으로 남는다."""
    cw, ch = CW / GW, CH / GH
    rects = plate if isinstance(plate, list) else [plate]
    filled = 0
    for i, v in enumerate(cells):
        if v >= MIN_EDGE:
            continue
        gx, gy = i % GW, i // GW
        x0, y0 = gx * cw, gy * ch
        # 글자·아이콘 위는 건드리지 않는다 — 가독성 보호
        if any(x0 + cw > r[0] and x0 < r[2] and y0 + ch > r[1] and y0 < r[3] for r in rects):
            continue
        filled += 1
        deficit = (MIN_EDGE - v) / MIN_EDGE
        for _ in range(int(3 + 8 * deficit)):
            cx = rng.uniform(x0, x0 + cw)
            cy = rng.uniform(y0, y0 + ch)
            r = rng.uniform(cw * 0.06, cw * 0.3)
            # 해당 지점 톤과 반대로 — 대비를 최대화
            col = ink if rng.random() < 0.5 else bg
            shape = rng.random()
            if shape < 0.4:
                d.line([(cx - r, cy - r * rng.uniform(-1, 1)),
                        (cx + r, cy + r * rng.uniform(-1, 1))],
                       fill=tone(col, rng.uniform(-40, 40)),
                       width=max(2, int(r * 0.4)))
            elif shape < 0.7:
                d.rectangle([cx - r * 0.7, cy - r * 0.7, cx + r * 0.7, cy + r * 0.7],
                            outline=tone(col, rng.uniform(-40, 40)),
                            width=max(2, int(r * 0.3)))
            else:
                d.ellipse([cx - r * 0.5, cy - r * 0.5, cx + r * 0.5, cy + r * 0.5],
                          fill=tone(col, rng.uniform(-40, 40)))
    return filled


def build(idx, card):
    cid, bg, ink = card["id"], card["bg"], card["ink"]
    rng = random.Random(0xA5C0 + idx * 7919)

    # icon 스타일은 배경이 눈에 띄면 안 된다. 잉크를 배경 쪽으로 당겨
    # 패턴 자체를 저대비로 만든다 (tone()의 TONE_SCALE과 함께 작용).
    if STYLE == "icon":
        ink = tuple(int(bg[i] + (ink[i] - bg[i]) * 0.93) for i in range(3))

    img = Image.new("RGBA", (CW, CH), bg + (255,))
    d = ImageDraw.Draw(img)

    composition_layer(d, rng, ink, bg)
    PATTERNS[card["pattern"]](d, rng, ink, bg)

    # 1단계: 판을 그리기 전에 카드 전면을 채운다.
    # 판 아래가 비어 있으면 반투명 판을 통해 그 공백이 그대로 비쳐서, 나중에 아무리
    # 주입해도 판 영역은 제외되므로 평평한 셀이 남는다. 그래서 먼저 전면을 메운다.
    whole = (0, 0, 0, 0)
    for _ in range(3):
        if inject_detail(d, rng, edge_energy_grid(img), ink, bg, whole) == 0:
            break

    if STYLE == "icon":
        plate = draw_icon_layout(img, d, card, bg, card["ink"])
    else:
        plate = draw_text_plate(img, d, card["name"], card["tag"], bg,
                                logo_path=os.path.join(LOGO_DIR, f"{cid}.png"))

    # 2단계: 판을 올린 뒤 남은 공백을 메운다. 판 안쪽은 가독성 때문에 건드리지 않는다.
    for _ in range(2):
        if inject_detail(d, rng, edge_energy_grid(img), ink, bg, plate) == 0:
            break

    draw_orientation_marks(d, idx, ink, bg)

    out = finalize(img)
    return cid, out, edge_energy_grid(out)


def main():
    os.makedirs(OUT, exist_ok=True)
    made = []
    print(f"  {'카드':<12} {'최소셀':>7} {'평균':>7} {'저밀도셀':>9}")
    print("  " + "-" * 40)
    for i, c in enumerate(CARDS):
        cid, img, cells = build(i, c)
        p = os.path.join(OUT, f"{cid}.png")
        img.save(p, dpi=(DPI, DPI))
        made.append((cid, p, img))
        low = sum(1 for v in cells if v < MIN_EDGE)
        print(f"  {cid:<12} {min(cells):>7.1f} {sum(cells)/len(cells):>7.1f} "
              f"{low:>6}/{len(cells)}")

    # 대조용 컨택트 시트 (3x3)
    tw = 420
    th = int(tw * H / W)
    sheet = Image.new("RGB", (tw * 3 + 40, th * 3 + 40), (255, 255, 255))
    for i, (_, _, img) in enumerate(made):
        sheet.paste(img.resize((tw, th), Image.LANCZOS),
                    (10 + (i % 3) * (tw + 10), 10 + (i // 3) * (th + 10)))
    sheet.save(os.path.join(OUT, "_contact_sheet.png"))

    # 패널에 띄울 콘텐츠. 레퍼런스 이미지 이름이 그대로 조회 키가 된다.
    content = [{"id": c["id"], "referenceImageName": c["id"], "name": c["name"],
                "tag": c["tag"], "summary": c["summary"], "detail": c["detail"]}
               for c in CARDS]
    with open(os.path.join(OUT, "cards.json"), "w", encoding="utf-8") as fp:
        json.dump(content, fp, ensure_ascii=False, indent=2)
        fp.write("\n")

    # 휘도 프로파일 상호 거리 — ARKit은 휘도로 인식하므로 색이 아니라 이걸 본다
    grays = [(cid, img.convert("L").resize((64, 90))) for cid, _, img in made]
    pairs = []
    for a in range(len(grays)):
        for b in range(a + 1, len(grays)):
            pa = list(grays[a][1].getdata())
            pb = list(grays[b][1].getdata())
            dist = sum(abs(x - y) for x, y in zip(pa, pb)) / len(pa)
            pairs.append((dist, grays[a][0], grays[b][0]))
    pairs.sort()
    print("\n  휘도 프로파일 최소 거리 3쌍 (낮을수록 오인식 위험):")
    for dist, x, y in pairs[:3]:
        print(f"    {x:<11} ↔ {y:<11} {dist:>6.1f}/255")
    print(f"\n  출력: {OUT}")


if __name__ == "__main__":
    main()
