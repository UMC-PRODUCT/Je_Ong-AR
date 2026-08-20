# 레퍼런스 카드 9장 — 인식 검증용 초안

실물 카드 뒷면으로 쓸 이미지 9장. **최종 인쇄물이 아니라 "9장이 서로 구분되어 인식되는가"를
실기기에서 확인하기 위한 검증용 초안이다.**

- 카드 실측 크기: **90 × 127 mm** (A4 한 장에 4장, 100% 인쇄)
- 파일: 1062 × 1500 px @ 300 DPI
- 생성기: `Tools/gen_reference_cards.py`, 인쇄 시트: `Tools/make_print_sheets.py`
- 9장 대조 보기: `cards/_contact_sheet.png`

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
| corelocation | 5 | 27.8 | 4/234 |
| apple-intelligence | 10 | 30.5 | 0/234 |
| cloudkit | 8 | 29.9 | 1/234 |
| coreml | 10 | 26.0 | 0/234 |
| foundation-models | 10 | 24.5 | 0/234 |
| liquid-glass | 10 | 28.7 | 0/234 |
| sirikit | 10 | 30.5 | 0/234 |
| nearby-interaction | 10 | 30.0 | 0/234 |
| widgetkit | 3 | 23.4 | 1/234 |

휘도 프로파일 상호 거리 (낮을수록 오인식 위험):

```
apple-intelligence ↔ liquid-glass  60.0 / 255
sirikit            ↔ widgetkit     60.3 / 255
corelocation       ↔ sirikit       61.5 / 255
```

**이 지표는 ARKit 인식률의 대리 측정이지 보증이 아니다.** 실제 인식률은 실기기 + 실제
인쇄물로만 확인된다.

<br>

## Xcode 등록 절차

현재 프로젝트에는 `.arresourcegroup`이 하나도 없다. 새로 만들어야 한다.

1. `UMCAR/UMCAR/Resources/Assets/Assets.xcassets` 열기
2. 우클릭 → **New AR Resource Group** → 이름 `TechCards`
3. `cards/` 안의 PNG 9장을 드래그
4. 각 이미지를 선택하고 인스펙터에서:
   - **Name**: 파일명과 동일하게 (`corelocation`, `apple-intelligence`, …)
     — `cards.json`의 `referenceImageName`과 일치해야 한다
   - **Units**: Millimeters
   - **Width**: `90`  (Height는 자동으로 127이 잡힌다)
5. 품질 경고(노란 삼각형)가 뜨는 이미지가 있는지 확인

> Contents.json을 직접 쓰지 않고 Xcode 인스펙터로 넣는다. 스키마를 손으로 쓰면 틀렸을 때
> 조용히 실패한다.

<br>

## 실기기 테스트 절차

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

- **실제 Apple 로고 미포함.** 지금은 기술명 텍스트 + 패턴만 있다. 로고를 넣으면 특징점 분포가
  바뀌므로 인식 재검증이 필요하다. 부스 배포물에 Apple 상표를 쓰는 건 상표 가이드라인 확인
  대상이다.
- **카드 크기 90 × 127 mm는 검증 대상이다.** 인식 거리가 부족하면 키운다.
- **패널 레이아웃 미정.** `cards.json`의 `detail`이 AR 패널에 어떻게 앉을지는
  `CardContentImageWriter` 수정과 함께 정한다.

<br>

## 재생성

```bash
cd Tools
OUT_DIR=../Docs/Assets/ReferenceCards/cards python3 gen_reference_cards.py
SRC_DIR=../Docs/Assets/ReferenceCards/cards \
DST_DIR=../Docs/Assets/ReferenceCards/print python3 make_print_sheets.py
```

시드가 고정되어 있어 같은 결과가 나온다. 카드 정의(이름·태그·설명·패턴·색)는
`gen_reference_cards.py`의 `CARDS` 배열 한 곳에 있고, `cards.json`도 여기서 함께 생성된다.
