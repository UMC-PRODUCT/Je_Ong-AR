# 설계 — 이미지 인식 기반 AR 전시물

> `IMPLEMENTATION.md`(전환 계획)를 코드와 대조 검증하고, 실기기 스파이크로 전제를
> 확인한 뒤 확정한 설계. 파일 참조는 `UMCAR/` 기준 상대 경로.
>
> 상태: **구현 완료 (Task 1~13, 15)** · 실기기 검증(Task 14)만 남음 ·
> 실행 기록은 `ROADMAP.md`

---

## 1. 무엇을 만드는가

책상에 펼쳐진 **실물 카드 9장**을 iPad로 비추면 ARKit이 각 카드의 인쇄된 뒷면을
`ARReferenceImage`로 식별하고, 화면에서 카드를 터치하면 그 카드 **바로 위 공간에
Apple 기술 설명 패널**이 떠오르는 부스 전시물.

가상 카드를 3D로 그리지 않는다. 실물 카드가 이미 존재하므로 AR은 **"어느 카드인지
식별"** 과 **"그 위에 정보를 띄우는"** 역할만 맡는다.

**게임이 아니다.** 점수·라이프·클리어·발음 채점이 없다. 관람객이 아무 때나 왔다 가는
부스 환경에 맞춘 열람형 전시물이다.

---

## 2. 확정된 결정

| 결정 | 근거 |
|---|---|
| 전시물로 간다 (게임성 제거) | 부스는 관람객이 아무 때나 왔다 간다. 850줄 상당의 게임 코드가 근거를 잃는다 |
| 카드 9장, 책상 고정 | 관람객이 집어 들지 않는다 |
| `maximumNumberOfTrackedImages = 0` | 추적을 끄면 4장 상한과 무관하게 9장 전부 앵커가 붙는다. **실기기에서 9장 개별 인식 확인** |
| 패널을 AR 공간의 quad로 | 부스 임팩트. `DynamicTexture` 4개 파일을 그대로 재사용 |
| 패널은 한 번에 한 장, 토글 | 관람객이 "지금 무엇을 보는지" 헷갈리지 않는다. 상태가 `selectedCardID` 하나로 끝난다 |
| SwiftData 전량 제거 | 9장은 고정된 읽기 전용 콘텐츠고 저장할 사용자 상태가 없다 |
| 기존 `ARCore` 골격 유지 + 게임 계층 절제 | 검증된 코드(`DynamicTexture`, SwiftUI↔AR 브리지)를 다시 쓰지 않는다. 실기기 없이는 검증이 안 되는 프로젝트에서 동작하는 코드를 버리는 건 손해가 크다 |

### 계획서에서 정정한 것

- **§4 "배경색을 서로 다르게"는 불충분하다.** ARKit 이미지 인식은 휘도 기반이다.
  컴파일된 에셋 카탈로그가 `ColorModel: Monochrome`으로 저장되는 것으로 실증됐다.
  9종은 색이 아니라 **명암 패턴 계열**이 달라야 한다.
- **§8-② "동시 추적 상한 4장"은 이 설계에 걸리지 않는다.** 상한은 *추적* 대상 수의
  상한이고, 추적을 끄면(기본값 0) 관측된 이미지마다 앵커가 붙는다.
- **§3 "패널 quad (+0.05m)"에 축이 빠져 있었다.** `+Z`가 아니라 **`+Y`**다.
- **§6 "한 줄 수정으로 끝"은 틀렸다.** `GameModelMapper.swift:19`가 `imageName`으로
  카드 앞면 `UIImage`를 만들고 있어 충돌한다. SwiftData를 걷어내면서 매퍼째 사라진다.
- **§4는 5장 기준으로 쓰여 있다.** 카드는 9장이다.
- `hasBootstrapped` 플래그는 `DataBootstrapper`가 아니라 `UMCARApp.swift:48,59`에 있다.

---

## 3. 상태 흐름

`GamePhase` 9개 → 3개.

```
initialized  ──startSession()──▶  scanning  ──첫 카드 인식──▶  browsing
 [StartOverlay]                [카드를 비춰주세요]        [탭 → 패널]
```

- `scanning → browsing`은 **단방향**이다. 9장 중 3장만 인식된 상태에서도 나머지를
  계속 찾을 수 있어야 하므로 "몇 장 찾았나"는 phase가 아니라 별도 카운트로 노출한다.
  되돌아가는 전이가 없어서 `handleRemovedAnchors`의 phase 가드 버그(§10)가 구조적으로
  재발하지 않는다.
- `finished`가 없다. 전시물에는 클리어가 없다.
- `paused`를 없앤다. 지금도 어디서도 설정되지 않는 유령 케이스고, 일시정지는 SwiftUI
  오버레이가 이미 처리한다.

---

## 4. 모듈 구조

`UMCAR` ← `ARCore` ← `Dependency` 3모듈 구성을 유지한다. `ARCoreDemoApp`이 실제로
`ARCore`를 단독 소비하고 있어 모듈 분리에 근거가 있다.

**`ARCore`에서 게임 개념을 완전히 몰아낸다.** 지금은 `ARContainerViewController`가
라이프 카운트·점수 계산·통과 판정을 들고 있는데 AR 모듈의 책임이 아니었다.
전환 후 `ARCore`의 책임은 둘로 좁혀진다:

1. 레퍼런스 이미지를 식별해 앵커를 붙인다
2. 탭된 카드를 알려주고, 그 위에 패널을 띄운다

**`ARCore`는 콘텐츠를 모른다.** 레퍼런스 이미지 집합과 카드 데이터는 앱이 주입한다.
`ARCore`가 앱 번들의 에셋을 직접 뒤지면 모듈 의존이 역전된다. 주입 통로는 지금
`GameSettings`가 카드를 받는 방식 그대로다:

```swift
public struct ExhibitSettings {          // 기존 GameSettings 자리
    let cards: [TechCard]                // §6
    let referenceImages: Set<ARReferenceImage>   // 앱이 에셋에서 로드해 넘긴다
    let fontSetting: ARCoreFontSetting
}
```

---

## 5. AR 파이프라인

### 세션 설정

```swift
let configuration = ARWorldTrackingConfiguration()
configuration.detectionImages = exhibitSettings.referenceImages   // 9장, 앱이 주입
configuration.maximumNumberOfTrackedImages = 0   // 추적 끔 → 앵커 고정, 4장 상한 무관
configuration.planeDetection = []                // 평면 감지 불필요
session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
```

`automaticImageScaleEstimationEnabled`는 켜지 않는다. 실물 크기를 정확히 아는
상황에서 스케일 추정을 켜면 앵커가 흔들린다.

`ARView`를 쓸 때 `automaticallyConfigureSession = false`를 먼저 세팅한다. 그러지 않으면
`detectionImages` 설정이 덮인다.

### 앵커 → 씬 그래프

```
AnchorEntity(anchor: ARImageAnchor)        ← 카드 실물 위치, 고정
 └── hitPlane : ModelEntity                ← generatePlane(width:depth:) = x-z 평면
      ├── CollisionComponent (박스, 실측 크기)
      ├── 투명 머티리얼 (렌더 안 됨, 히트 판정만)
      ├── TechCardComponent(cardID:)
      └── panel : ModelEntity              ← position [0, 0.05, 0]  ← +Y
           ├── generatePlane(width:depth:)
           ├── UnlitMaterial(texture:)
           └── isEnabled = false           ← 탭 전까지 숨김
```

**좌표계.** `ARImageAnchor`의 로컬 공간은 **이미지가 x-z 평면에 눕고 +Y가 법선**이다
(Apple 샘플 주석: *"ARImageAnchor assumes the image is horizontal in its local space"*).
RealityKit의 `generatePlane(width:depth:)`도 x-z 평면이라 **회전 보정이 필요 없다.**
패널을 띄울 때는 `+Y`로 민다.

**`UnlitMaterial`을 쓰는 이유**: 부스 조명이 어두워도 텍스트가 어둡게 깔리지 않는다.

**중복 부착 방어는 사실상 공짜다.** Apple 문서: *"ARKit adds an image anchor to a
session exactly once for each reference image."* 그래도 이름 불일치·미등록 카드는
로그를 남기고 무시한다.

### 탭 처리

`UITapGestureRecognizer`를 `arView`에 직접 붙인다. 지금은 SwiftUI가 `trigger*` Bool을
토글해 AR에 명령을 밀어넣는 구조인데(트리거 5개), 탭 좌표를 SwiftUI로 왕복시킬 이유가
없다.

```
handleTap(at:)
 → arView.entity(at:) → TechCardComponent 보유 조상 탐색
 → nil        : 열린 패널 닫기 (빈 곳 탭 = 닫기)
 → 같은 카드  : 토글
 → 다른 카드  : 이전 닫고 새로 열기
```

**이 선택 규칙을 `CardSelection`이라는 순수 값 타입으로 분리한다.** ARKit·RealityKit
의존이 없어서 시뮬레이터에서 유닛 테스트가 된다 — 실기기 없이 검증 가능한 유일한
로직 조각이라 반드시 떼어낸다.

```swift
struct CardSelection: Equatable {
    private(set) var selected: String?
    mutating func tap(_ cardID: String?) { ... }   // nil = 빈 곳
}
```

### 텍스처

`ARCore/Sources/Features/DynamicTexture/` 4개 파일을 재사용한다.
`CardContentImageWriter.imageFrom()`(`:76`)의 레이아웃만 조정한다
(영단어 + 한글뜻 2줄 → 로고 + 기술명 + 설명 문단).

`DynamicCardContentSystem`이 매 프레임 쿼리로 굽는 구조인데, 9장 고정이면 **세션 시작 시
전량 웜업**이 낫다. `CardContentImageProvider`에 이미 웜업 경로가 있고, 부스에서 탭 후
텍스처가 늦게 뜨는 것보다 낫다.

---

## 6. 데이터

SwiftData를 전량 제거한다. 9장은 고정된 읽기 전용 콘텐츠고 저장할 사용자 상태가 없다.

```swift
struct TechCard: Identifiable, Hashable {
    let id: String          // == ARReferenceImage.name. UUID 불필요
    let name: String        // "CoreLocation"
    let tag: String         // "위치·방향"
    let summary: String     // 한 줄 요약
    let detail: String      // 패널 설명 문단
    let logoAssetName: String?
}
```

`id`를 레퍼런스 이미지 이름으로 삼으면 매핑이 조회 한 줄이 된다.

```
ARImageAnchor.referenceImage.name  ==  TechCard.id  →  TechCard 조회
```

앱에서는 JSON을 읽지 않고 **Swift 배열 상수 `TechCard.all`**로 둔다. 파싱 실패 경로가
없고 컴파일 타임에 검증된다.

콘텐츠 원본은 `Tools/gen_reference_cards.py`의 `CARDS` 배열 한 곳이다. 여기서
카드 이미지와 `cards.json`이 함께 생성된다. `TechCard.all`은 그 `cards.json`을 보고
쓴 사본이므로, 콘텐츠가 바뀌면 **양쪽을 함께 고쳐야 한다.** 어긋나면 카드 뒷면과
패널 내용이 따로 논다.

이 이중화를 감수하는 이유: 앱이 런타임에 JSON을 파싱하면 부스에서 실패할 경로가
생기고, 반대로 빌드 시 코드 생성을 붙이면 9장짜리 고정 콘텐츠에 비해 장치가 과하다.
대신 §11의 무결성 테스트가 `TechCard.all`과 실제 등록된 레퍼런스 이미지 이름의
1:1 대응을 검사해 어긋남을 잡는다.

사라지는 것: `CardModel` `LevelModel` `CategoryModel` `GameSessionModel` `UsedCardModel`
`GameModelMapper` `DataBootstrapper`(205줄) `hasBootstrapped` 플래그 로직.

---

## 7. SwiftUI 계층

`ARContainer` 바인딩 13개 → **4개**, 트리거 5개 → **1개**.

| 남김 | 삭제 |
|---|---|
| `exhibitPhase` `arError` `detectedCardCount` `selectedCardID` | `currentLifeCounts` `currentGameScore` `numberOfFinishedCards` `flippedCardId` `cardSubmissions` `currentDetectedPlanes` `triggerCreatePortal` `triggerPlaceCards` `triggerFlipCard` `triggerSubmitAccuracy` |

델리게이트 5개 → 3개. `didChangeLifeCount` `didChangeScore` 삭제,
`arContainerDidFind/LosePlaneAnchor` → `didDetectCard`.

오버레이 3개:

- `StartOverlay` (유지) — 세션 시작
- `ScanGuideOverlay` — "카드를 비춰주세요" + n/9 카운트 (`CheckScanOverlay` 개조)
- `BrowsingOverlay` — 최소 구성. 종료 버튼, 인식 수

`PlayingGameOverlay`의 조준점 `Image(.aim)`과 좌우 `targetBtn` 2개(`:40-58`)를 삭제한다.
카드를 직접 터치하므로 조준 개념이 사라진다.

---

## 8. 인쇄물 사양

인쇄물 품질이 인식률을 그대로 결정한다. 상세는
`Docs/Assets/ReferenceCards/README.md`, 생성기는 `Tools/gen_reference_cards.py`.

- 카드 **90 × 127 mm** (A4 한 장에 4장, 100% 인쇄)
- **명암 패턴 계열을 9종 전부 다르게.** 색만 다르면 오인식된다 (§2 정정 참조)
- 로고 단독 금지 — 로고 + 기술명 텍스트 + 비대칭 배경.
  **로고는 텍스트 판 안쪽에만 놓는다.** 평면 벡터라 크게 깔면 특징점 영역을 잠식한다
- **무광 인쇄.** Apple 문서: *"reflections on those surfaces can interfere with detection"*
- 실물 인쇄본을 촬영해 등록, 물리 크기를 정확히 입력
- Xcode 품질 경고 0

**actool이 레퍼런스 이미지를 453×640으로 다운샘플한다.** 이것이 ARKit이 실제로 보는
해상도이므로 그보다 고운 디테일은 인식에 기여하지 않는다.

---

## 9. 빌드 시 검증 — 조용히 망가지는 지점

`.arresourcegroup`의 `unit`은 **`centimeters` / `inches` / `meters`만 유효하다.**
`millimeters`를 넣으면:

```
actool 컴파일   → 에러 없음 (exit 0)
Physical Size  → 0.01,0.01     ← 90×127mm가 아니라 1×1cm
```

빌드는 통과하는데 앵커가 엉뚱한 거리에 붙는다. Apple 문서도 경고한다:
*"Entering an incorrect physical size will result in an ARImageAnchor that's the wrong
distance from the camera."*

그래서 리소스 그룹은 손으로 만들지 않고 스크립트로 만들고, 컴파일된 `.car`를 열어
검증한다.

```bash
python3 Tools/make_ar_resource_group.py
Tools/verify_ar_resource_group.sh        # actool 컴파일 → assetutil로 물리 크기 확인
```

카드 크기를 바꾸면 `verify_ar_resource_group.sh`의 `EXPECT_SIZE`도 함께 고칠 것.

---

## 10. 삭제 목록

총 **2,394줄** + usdz 패키지(11개 파일).

### `ARCore` — 965줄

| 파일 | 줄 | 이유 |
|---|---:|---|
| `Features/AR/CentralPortalVisualizer.swift` | 149 | 포탈 연출 제거 |
| `UIComponents/ARContainerViewController+CardPlacement.swift` | 136 | 배치할 카드 없음 (실물이 이미 있음) |
| `UIComponents/ARContainerViewController+PlaneDetection.swift` | 131 | `+ImageDetection.swift`로 교체 |
| `UIComponents/ARContainerViewController+Portal.swift` | 127 | 포탈 제거 |
| `Features/AR/PlaneVisualizer.swift` | 82 | 평면 스캔 제거 |
| `Features/AR/CardRotator.swift` | 80 | 뒤집기는 사람이 실물로 함 |
| `UIComponents/ARContainerViewController+Score.swift` | 69 | 점수·라이프·통과 판정 제거 |
| `Components/HoverComponent.swift` | 47 | 조준 방식 폐기 |
| `UIComponents/ARContainerViewController+Hover.swift` | 38 | 〃 |
| `UIComponents/ARContainerViewController+CardFlipper.swift` | 36 | 뒤집기 제거 |
| `System/HoverSystem.swift` | 34 | 조준 방식 폐기 |
| `Features/AR/ARFeatureProvider.swift` | 21 | 구현체 2개에 비해 과한 추상화. `associatedtype` 때문에 존재 타입으로 담기지도 않는다 |
| `Data/GameCardSubmission.swift` | 15 | 점수 제출 개념 소멸 |
| `Packages/KonglishARProject` | — | usdz 카드 씬 미사용 |

### `UMCAR` 앱 — 1,429줄

| 파일 | 줄 | 이유 |
|---|---:|---|
| `Presentation/AR/ViewModels/DetailCardViewModel.swift` | 297 | STT/TTS/Levenshtein/무음 감지 |
| `Common/UIComponents/AR/WordDetailCard.swift` | 221 | 발음 UI |
| `Model/DataBootstrapper.swift` | 205 | SwiftData 주입 |
| `Common/UIComponents/AR/GameStatus.swift` | 95 | 점수·라이프 표시 |
| `Common/Enum/Level/LevelType.swift` | 83 | 레벨 개념 소멸 |
| `Common/Enum/AR/AccuracyType.swift` | 76 | 발음 채점 |
| `Common/UIComponents/AR/CompleteWindow.swift` | 75 | 클리어 연출 |
| `Common/UIComponents/AR/FailureWindow.swift` | 72 | 실패 연출 |
| `Common/UIComponents/AR/AudioBand.swift` | 67 | 음성 입력 표시 |
| `Common/UIComponents/AR/LifeHeart.swift` | 45 | 라이프 표시 |
| `Presentation/Overlay/Views/FinishedOverlay.swift` | 34 | 종료 개념 소멸 |
| `Model/Domain/*.swift` (5개) | 136 | SwiftData 모델 |
| `Model/Domain/GameModelMapper.swift` | 23 | 매핑 소멸 |

---

## 11. 테스트 전략

실기기 없이는 AR 경로 검증이 불가하다. 그래서 **테스트 가능한 것을 의도적으로 분리한다.**

| 대상 | 방법 | 환경 |
|---|---|---|
| `CardSelection` (선택 토글 규칙) | 유닛 테스트 | 시뮬레이터 |
| `TechCard.all` 무결성 | id 중복 없음, 9개, 레퍼런스 이미지 이름과 1:1 | 시뮬레이터 |
| `CardContentImageWriter` | 카드 → 이미지 생성 성공 | 시뮬레이터 (UIKit만 필요) |
| `.arresourcegroup` 물리 크기 | `Tools/verify_ar_resource_group.sh` | CI 가능 |
| 앵커 부착·히트 테스트·패널 배치 | 수동 체크리스트 | **실기기 필수** |

`ARCoreDemoApp`의 `ImageDetectionProbeView`가 인식 검증 경로다. 본 구현이 올라오면
폐기하거나 대체한다.

---

## 12. 리스크와 미결

| 리스크 | 영향 | 대응 |
|---|---|---|
| 부스 조명이 어둡거나 반사 | 인식률 저하 | 무광 인쇄, 부스 조명 조건에서 실측 |
| 카드가 작으면 인식 거리 짧음 | UX 저하 | 90×127mm는 검증 대상. 부족하면 키운다 |
| 실기기 없이 검증 불가 | 개발 속도 | 시뮬레이터에서 이미지 인식 불가. 실기기 상시 확보 |
| Apple 상표 사용 | 배포물 | 부스 인쇄물에 Apple 로고를 넣는다면 상표 가이드라인 확인 |

**미결**

- **패널 레이아웃.** `detail` 문단이 quad에 어떻게 앉을지는
  `CardContentImageWriter` 수정과 함께 정한다. 텍스처 해상도와 읽기 거리의 트레이드오프.
- **빌보드 처리.** 패널을 카드와 같은 방향으로 띄운다. 카드를 터치하려면 어차피 그쪽을
  보고 있으므로 필요해지면 추가한다 (`iOS 18+`의 `BillboardComponent` 또는
  `SceneEvents.Update`에서 look-at).
- **좌표계 실물 확인.** Apple 샘플 주석이라는 문서 근거는 있으나, 패널이 실제로
  카드 바로 위에 뜨는지는 아직 눈으로 확인되지 않았다. **구현이 이 가정 위에 서 있다** —
  틀렸다면 `CardPanelBuilder`의 축을 바꿔야 한다.
- **Apple 상표 확인.** 카드에 Apple 기술 아이콘이 들어갔다. 부스 배포 인쇄물이므로
  상표 가이드라인을 한 번 확인해 둘 것. (로고 자체는 반영 완료 — 인식 지표 재측정도
  마쳤다.)

---

## 13. 기존 코드에서 발견된 문제

전환 과정에서 함께 정리한다. 전부 코드에서 실재를 확인했다.

- `GamePhase.paused`는 선언만 되고 **어디서도 설정되지 않는다.**
- `+CardPlacement.swift:14`의 `placeCards()`는 `public`인데 **호출부가 없다**
  (포탈 경로로 대체된 죽은 코드).
- `WordDetailCard.swift:84`가 `.onChange(of: accuracyPercent)`로 점수를 제출한다.
  `accuracyPercent`의 초기값이 0이고 `ARView.swift:127`이 0으로 되돌리므로,
  **첫 시도가 0%면 값이 안 바뀌어 제출 자체가 누락된다.**
- `Score.swift:30`이 통과/실패와 무관하게 `isCompleted = true`를 박는다.
  `CardFlipper.swift:26`과 `CardRotator.swift:44`가 완료된 카드를 막으므로
  **한 번 틀리면 그 카드는 다시 뒤집을 수 없다.**
- `ARView.swift:41-42`의 `gameCards`가 computed property + `shuffled()`라 body
  재평가마다 다시 섞인다. `GameSettings`가 최초 1회만 캡처해 게임에는 영향이 없으나 낭비.
- `handleRemovedAnchors`(`+PlaneDetection.swift:77`)가 `.scanning`에서만 동작해
  `.scanned` 도달 후에는 평면을 잃어도 카운트가 줄지 않는다.
- `ARCoreDemoApp/ContentView.swift`에 `cardSubmissions` 바인딩이 빠져 있어
  **데모 타깃이 컴파일되지 않았다** (검증 작업 중 수정함).
