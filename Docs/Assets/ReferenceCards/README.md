# 레퍼런스 카드 9장 — 인식 검증용 초안

실물 카드 뒷면으로 쓸 이미지 9장. **최종 인쇄물이 아니라 "9장이 서로 구분되어 인식되는가"를
실기기에서 확인하기 위한 검증용 초안이다.**

- 카드 실측 크기: **90 × 127 mm** (A4 한 장에 4장, 100% 인쇄)
- 파일: 1062 × 1500 px @ 300 DPI
- 생성기: `Tools/gen_reference_cards.py`, 인쇄 시트: `Tools/make_print_sheets.py`
- 9장 대조 보기: `cards/_contact_sheet.png`
- 로고: `logos/*.png` (`Tools/normalize_logos.py`가 정규화)

| # | 파일 | 표시명 | 태그 | 패턴 계열 |
|---:|---|---|---|---|
| 1 | `corelocation.png` | CoreLocation | 위치·방향 | 편심 방사선 |
| 2 | `apple-intelligence.png` | Apple Intelligence | 온디바이스 개인 지능 | 노드-엣지 그래프 |
| 3 | `cloudkit.png` | CloudKit | iCloud 동기화 | 편심 동심호 |
| 4 | `coreml.png` | CoreML | 온디바이스 머신러닝 | 회전 사각형 격자 |
| 5 | `foundation-models.png` | Foundation Models | 내장 LLM · iOS 26 | 어긋난 벽돌 |
| 6 | `liquid-glass.png` | Liquid Glass | iOS 26 디자인 | 사선 밴드 |
| 7 | `sirikit.png` | SiriKit | 음성·단축어 연동 | 셰브론 파편 |
| 8 | `nearby-interaction.png` | Nearby Interaction | 초광대역 정밀 측위 | 산개 삼각형 |
| 9 | `widgetkit.png` | WidgetKit | 위젯·라이브 액티비티 | L자 코너 조각 |

패턴은 기술의 인상에 맞춰 배정했다 (측위→방사선, AI→그래프, 동기화→동심호 …).

**로고는 텍스트 판 안쪽 왼편에만 놓는다.** Apple 기술 아이콘은 평면 벡터라 특징점이
빈약하다. 크게 깔면 인식에 쓸 고주파 영역을 그만큼 잡아먹는다. 판 안은 이미 밀도 주입
제외 영역이라 로고를 넣어도 특징 밀도가 더 나빠지지 않고, 로고 둘레에 테두리를 둘러
격자 셀을 가로지르는 엣지를 만든다.
우하단 인덱스 바 개수가 위 표의 번호다 — 실기기 테스트에서 어느 카드가 인식됐는지
대조할 때 쓴다. 좌상단 웨지는 방향 표시다.

카드 뒷면에는 **이름 + 짧은 태그만** 넣는다. 긴 설명은 AR 패널에 띄울 내용이라
`cards/cards.json`에 따로 담았다 (`summary` 한 줄 + `detail` 문단). 이 파일이 §3 설계의
`TechCard` 데이터가 된다 — `referenceImageName`이 곧 조회 키다.

<br>

## 설계 근거

ARKit 이미지 인식은 **휘도(luminance) 기반 특징점**으로 동작한다. 색이 아무리 달라도 명암
구조가 비슷하면 서로 오인식된다. 그래서 9종을 색이 아니라 **명암 패턴 계열 자체를 다르게**
설계했다.

Apple 문서에서 확인한 제약:

- *"ARKit adds an image anchor to a session exactly once for each reference image"* — 9장 각각
  정확히 한 번 앵커가 붙는다
- *"reflections on those surfaces can interfere with detection"* — 유광 코팅 금지
- *"Enter the physical size of the image in Xcode as accurately as possible"* — 90 × 127 mm

<br>

## 측정된 품질 지표

추측이 아니라 실측값이다. 생성기가 국소 고주파 에너지를 13×18 격자(234셀)로 재고, 임계값
미만 셀에 디테일을 주입해 특징점 공백을 없앤다.

| 카드 | 최소 셀 | 평균 | 저밀도 셀 |
|---|---:|---:|---:|
| corelocation | 10 | 28.9 | 0/234 |
| apple-intelligence | 6 | 30.8 | 4/234 |
| cloudkit | 11 | 29.8 | 0/234 |
| coreml | 10 | 26.2 | 0/234 |
| foundation-models | 5 | 24.7 | 3/234 |
| liquid-glass | 10 | 29.1 | 0/234 |
| sirikit | 10 | 30.6 | 0/234 |
| nearby-interaction | 5 | 29.9 | 4/234 |
| widgetkit | 9 | 24.4 | 2/234 |

로고가 있는 판 주변이 약한 셀로 남는다 — 플랫한 아이콘에서 불가피한 부분이다.
카드 전면 기준으로는 공백이 없다.

휘도 프로파일 상호 거리 (낮을수록 오인식 위험):

```
apple-intelligence ↔ liquid-glass  58.2 / 255
sirikit            ↔ widgetkit     60.1 / 255
cloudkit           ↔ widgetkit     60.8 / 255
```

### ARKit이 실제로 보는 해상도(453x640, 흑백)에서

actool 다운샘플과 흑백 변환을 거친 뒤에도 유지되는지 확인한 값이다.

| 카드 | 최소 셀 | 저밀도 셀 |
|---|---:|---:|
| corelocation | 8 | 0/234 |
| apple-intelligence | 5 | 1/234 |
| cloudkit | 9 | 0/234 |
| coreml | 8 | 0/234 |
| foundation-models | 4 | 3/234 |
| liquid-glass | 8 | 0/234 |
| sirikit | 9 | 0/234 |
| nearby-interaction | 4 | 2/234 |
| widgetkit | 8 | 0/234 |

흑백 변환 후 휘도 최소거리: `apple-intelligence ↔ liquid-glass = 58.0/255`
(원본 58.2에서 거의 그대로 — 구분도가 다운샘플을 견딘다)

**이 지표는 ARKit 인식률의 대리 측정이지 보증이 아니다.** 실제 인식률은 실기기 + 실제
인쇄물로만 확인된다.

<br>

## AR Resource Group 생성

스크립트로 만든다. 스키마는 추측이 아니라 `actool` 컴파일 결과로 확인했다.

```bash
cd Tools
python3 make_ar_resource_group.py          # 기본: ARCoreDemoApp에 생성
./verify_ar_resource_group.sh              # 컴파일해서 물리 크기까지 검증
```

`XCASSETS` 환경변수로 대상 카탈로그를 바꿀 수 있다 (UMCAR 본 앱에 넣을 때 사용).

### ⚠️ unit을 틀리면 조용히 망가진다

`unit`은 **`centimeters` / `inches` / `meters`만 유효하다.** `millimeters`를 넣으면:

```
actool 컴파일   → 에러 없음 (exit 0)
Physical Size  → 0.01,0.01   ← 90x127mm가 아니라 1x1cm
```

빌드는 통과하는데 앵커가 엉뚱한 거리에 붙는다. 그래서 `verify_ar_resource_group.sh`가
컴파일된 `.car`를 열어 실제 값을 확인한다. 카드 크기를 바꾸면 이 스크립트의
`EXPECT_SIZE`도 함께 고칠 것.

### 컴파일 결과에서 확인된 사실

```
AssetType: "Recognition Group"   Name: TechCards            9장
AssetType: "Recognition Image"   Physical Size: 0.09,0.13
                                 ColorModel: Monochrome     ← ARKit은 흑백으로 저장
                                 PixelWidth: 453 x 640      ← actool이 다운샘플
```

- **흑백 저장**이 "색이 아니라 휘도"라는 설계 근거를 실증한다. 배경색만 다르게 해서는
  오인식을 막을 수 없다.
- **453x640으로 다운샘플**된다. 이게 ARKit이 실제로 보는 해상도이므로, 그보다 고운
  디테일은 인식에 기여하지 않는다. 생성기의 측정 스케일을 여기에 맞췄다.

<br>

## 실기기 테스트 절차

검증용 화면이 `ARCoreDemoApp`에 있다 —
`ARCoreDemoApp/Sources/ImageDetectionProbeView.swift`.

```bash
cd ARCoreDemoApp
mise exec tuist@4.155.0 -- tuist install
mise exec tuist@4.155.0 -- tuist generate
# Xcode에서 실기기 선택 후 실행 → "이미지 인식 검증" 메뉴
```

화면에 9장 체크리스트, 인식된 카드의 실측 크기(90x127mm로 나와야 한다), 인식까지
걸린 시간이 표시된다. 인식된 카드 위에는 마커가 뜬다:

- **초록 판**이 실물 카드에 정확히 겹치는가
- **하늘색 판**이 카드에서 5cm 떠 있는가

이 둘이 맞으면 설계 §2의 좌표계 가정(ARImageAnchor 로컬 +Y가 카드 법선)이 검증된 것이다.
판이 옆으로 서거나 카드를 파고들면 가정이 틀린 것이므로 설계를 고쳐야 한다.

1. `print/_print_sheet_1..3.png`를 **100% 배율, 무광 용지**로 인쇄 (축소 인쇄 금지 —
   물리 크기가 틀어지면 앵커 위치가 어긋난다)
2. 재단선을 따라 자른다
3. 9장을 책상에 펼친다
4. iPad로 훑으며 확인:
   - 9장이 **각각** 인식되는가 (인덱스 바로 어느 카드인지 대조)
   - 서로 **오인식**되는 쌍이 있는가
   - 인식되는 **거리**가 부스에서 쓸 만한가
   - 부스 조명 조건에서도 되는가

화면에 띄워서 하는 1차 테스트도 가능하지만, 화면 반사 때문에 실전 조건과 다르다. 인쇄물
검증을 건너뛰면 안 된다.

<br>

## 아직 안 정해진 것

- **Apple 상표.** 부스 배포 인쇄물에 Apple 기술 아이콘을 쓰므로 상표 가이드라인을
  한 번 확인해 둘 것.
- **로고 원본 해상도.** 일부 아이콘이 256x256이다. 90mm 카드에서 로고가 약 8mm이므로
  300dpi 기준 필요 해상도는 넘지만, 크게 키우려면 고해상도 원본이 필요하다.
- **카드 크기 90 × 127 mm는 검증 대상이다.** 인식 거리가 부족하면 키운다.
- **패널 레이아웃 미정.** `cards.json`의 `detail`이 AR 패널에 어떻게 앉을지는
  `CardContentImageWriter` 수정과 함께 정한다.

<br>

## 재생성

```bash
cd Tools
python3 normalize_logos.py                 # 로고 원본 → logos/ (최초 1회)
OUT_DIR=../Docs/Assets/ReferenceCards/cards python3 gen_reference_cards.py
SRC_DIR=../Docs/Assets/ReferenceCards/cards \
DST_DIR=../Docs/Assets/ReferenceCards/print python3 make_print_sheets.py
```

시드가 고정되어 있어 같은 결과가 나온다. 카드 정의(이름·태그·설명·패턴·색)는
`gen_reference_cards.py`의 `CARDS` 배열 한 곳에 있고, `cards.json`도 여기서 함께 생성된다.
