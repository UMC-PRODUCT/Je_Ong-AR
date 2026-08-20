# 구현 계획 — 이미지 인식 기반 AR 카드로 전환

> 기존 Konglish(영어 발음 학습 게임) 구조를 실물 카드 이미지 인식 방식으로 교체하는 작업 문서.
> 파일 참조는 `UMCAR/` 기준 상대 경로.

---

## 1. 무엇을 바꾸는가

| | 기존 (as-is) | 신규 (to-be) |
|---|---|---|
| 인식 대상 | 수직 **평면** 5개 (면적 0.5㎡ 이상) | 실물 카드 뒷면 **로고 이미지** |
| 카드 실체 | 가상 3D 카드 (usdz) | **실물 인쇄 카드** |
| 카드 배치 | 포탈 연출로 공중에서 배치 | 배치 없음 — 이미 책상에 있음 |
| 선택 방식 | 화면 중앙 조준점 + 좌우 버튼 | **카드를 직접 터치** |
| 콘텐츠 | 영단어 + 발음 채점 (STT) | **Apple 기술 로고 + 설명 텍스트** |
| 뒤집기 | `CardRotator`로 3D 회전 | 없음 — 사람이 실물로 뒤집음 |

핵심 판단: **실물 카드가 물리적으로 존재하므로 가상 카드를 3D로 그릴 이유가 없다.**
AR은 "어느 카드인지 식별" + "그 위에 정보 패널 띄우기"만 담당한다.

---

## 2. 기존 흐름 (참고)

`GamePhase` 상태 머신이 전체를 구동하고 SwiftUI는 오버레이만 교체한다.

```
initialized → scanning → scanned → portalCreating → portalCreated → cardPlacing → playing → finished
   [시작]      [평면 5개]  [포탈]     [3초 흡입]      [카드 뿌리기]   [n*0.3+2.5초]  [발음]   [종료]
```

- SwiftUI → AR: `trigger*` Bool 바인딩 (`ARCore/Sources/UIComponents/ARContainer.swift`)
- AR → SwiftUI: `ARContainerViewControllerDelegate` 콜백으로 역방향 push

이 중 `scanned` 이후 `playing` 이전 구간(포탈·흡입·카드 배치)이 통째로 사라진다.

---

## 3. 신규 흐름

```
initialized → scanning → browsing
   [시작]     [카드 인식]  [터치 → 패널 열람]
```

### 씬 구조

```
ARImageAnchor  (실물 카드 위치 — ARKit이 부여)
 ├── 투명 콜라이더 판     ← 터치 히트 판정용, 카드와 동일 크기
 └── 패널 quad (+0.05m)  ← 로고 + 설명 텍스처, 터치 시 표시
```

패널은 카드와 같은 방향으로 살짝 띄운다. 카드를 터치하려면 어차피 그쪽을 보고 있으므로
빌보드(항상 카메라 향하기) 처리는 필요해지면 추가한다. `iOS 18+`의 `BillboardComponent`
또는 `SceneEvents.Update`에서 look-at 처리.

---

## 4. 카드 뒷면 인쇄 요구사항 ⚠️

**이 문서에서 가장 중요한 절.** 인쇄물 품질이 인식률을 그대로 결정한다.

Apple 기술 로고는 대부분 **플랫 벡터 + 큰 단색 면적**이다. ARKit이 요구하는 것은
정반대(고주파 디테일, 균일하게 분포된 특징점)이므로, 로고를 흰 배경에 단독으로 크게
배치하면 Xcode가 품질 경고를 띄우고 실제 조명에서 인식이 흔들린다.

### 지켜야 할 것

- [ ] **로고 단독 금지.** 로고 + 기술 이름 텍스트 + 비대칭 배경 패턴으로 구성한다.
      텍스트가 특징점을 대량 공급한다.
- [ ] **5장의 배경색·패턴을 서로 다르게.** 상호 오인식을 막는다.
- [ ] **무광 인쇄.** 코팅 반사는 인식률을 붕괴시킨다.
- [ ] **실물 인쇄본을 촬영해서 등록한다.** 화면 캡처 이미지로 등록하면 실전 조건과 어긋난다.
- [ ] **물리적 크기(미터)를 정확히 입력한다.** 틀리면 앵커 위치가 어긋난다.
- [ ] 인쇄 후 Xcode AR Resource Group의 품질 경고가 없는지 확인한다.

### 등록 위치

`UMCAR/Resources/Assets/Assets.xcassets`에 **AR Resource Group을 새로 만든다.**
현재 프로젝트에는 `.arresourcegroup`이 하나도 없다.

각 레퍼런스 이미지의 이름은 `GameCard.imageName`과 일치시킨다 (§6 참조).

> 부스에 배포되는 인쇄물에 Apple 상표를 사용하므로 Apple 상표 가이드라인을 한 번 확인해 둘 것.

---

## 5. 파일별 작업 목록

### 수정

| 파일 | 작업 |
|---|---|
| `ARCore/.../ARContainerViewController+ARSetup.swift:54` | `planeDetection = [.vertical]` → `detectionImages` + `maximumNumberOfTrackedImages` |
| `ARCore/.../ARContainerViewController+PlaneDetection.swift` | `+ImageDetection.swift`로 교체. `ARPlaneAnchor` 면적 검사 → `ARImageAnchor` 처리 |
| `ARCore/Sources/Features/AR/CardDetector.swift:51` | `arView.hitTest(centerPoint)` → 탭 좌표를 인자로 받도록 변경 |
| `ARCore/Sources/Features/AR/CardPositioner.swift` | 3D 카드 생성 → 콜라이더 판 + 패널 quad 생성으로 축소 |
| `ARCore/Sources/Data/GameSettings.swift:21` | `minimumSizeOfPlane` 제거 |
| `ARCore/Sources/Data/GamePhase.swift` | 9개 → 3개 (`initialized`/`scanning`/`browsing`) |
| `ARCore/Sources/UIComponents/ARContainer.swift` | 포탈·카드배치 트리거 제거, 탭 좌표 전달 추가 |
| `ARCore/.../DynamicTexture/CardContentImageWriter.swift:76` | `imageFrom()` 레이아웃을 로고 + 설명문에 맞게 조정 (§7) |
| `UMCAR/.../Presentation/AR/Views/ARView.swift:55` | `minimumSizeOfPlane` 제거, 오버레이 switch 축소 |
| `UMCAR/.../Presentation/Overlay/Views/PlayingGameOverlay.swift:40-58` | 조준점(`Image(.aim)`)·타겟 버튼 제거, 탭 제스처로 대체 |
| `UMCAR/.../Model/Domain/GameModelMapper.swift:16` | `imageName`에 레퍼런스 이미지 이름을 매핑 |

### 삭제

| 파일 | 이유 |
|---|---|
| `ARCore/.../ARContainerViewController+Portal.swift` | 포탈·흡입 연출 불필요 |
| `ARCore/.../ARContainerViewController+CardPlacement.swift` | 배치할 카드가 없음 (실물이 이미 있음) |
| `ARCore/.../ARContainerViewController+CardFlipper.swift` | 뒤집기는 사람이 실물로 함 |
| `ARCore/Sources/Features/AR/CardRotator.swift` | 위와 동일 |
| `ARCore/Sources/Features/AR/PlaneVisualizer.swift` | 평면 스캔 제거 |
| `ARCore/Sources/Features/AR/CentralPortalVisualizer.swift` | 포탈 제거 |
| `ARCore/Sources/System/HoverSystem.swift` + `Components/HoverComponent.swift` | 조준 방식 폐기 |
| `ARCore/Packages/KonglishARProject` (usdz 카드 씬) | 3D 카드 미사용 |

### 신규

| 파일 | 내용 |
|---|---|
| `ARCore/.../ARContainerViewController+ImageDetection.swift` | `ARImageAnchor` 감지 → 콜라이더·패널 부착 |
| `Assets.xcassets/GameCards.arresourcegroup` | 카드 뒷면 레퍼런스 이미지 (§4) |

---

## 6. 매핑은 이미 자리가 있다

`GameCard.imageName`(`ARCore/Sources/Data/GameCard.swift:17`)은 현재 3D 배치에 쓰이지 않고
SwiftUI 이미지 표시에만 사용된다. 여기에 레퍼런스 이미지 이름을 태우면
`GameModelMapper.swift:16` 한 줄 수정으로 매핑이 끝난다. **SwiftData 스키마 변경 불필요.**

```
ARImageAnchor.referenceImage.name  ==  GameCard.imageName  →  GameCard 조회
```

설명 텍스트는 `CardModel`의 기존 필드를 재사용하거나(`wordKor` → 설명문) 필드를 추가한다.
`DataBootstrapper`가 `hasBootstrapped` UserDefaults 플래그로 최초 1회만 주입하므로,
스키마를 바꾸면 이 플래그를 리셋해야 한다.

---

## 7. 재사용 자산 — DynamicTexture

`ARCore/Sources/Features/DynamicTexture/` 4개 파일은 **삭제 대상이 아니라 핵심 재사용 자산이다.**

`CardContentImageWriter.imageFrom()`(`:76`)이 지금 하는 일:

```
배경 채우기 → 이미지 draw(280×280) → 영문 제목 draw → 국문 부제목 draw → PNG 반환
```

원하는 "로고 이미지 + 설명 텍스트 패널"과 **구조가 동일하다.** 텍스트 rect를 설명문 길이에
맞게 넓히고 폰트 크기를 줄이는 정도의 수정으로 끝난다.

`CardContentImageProvider`(actor, 캐시 + 웜업)와 `DynamicCardContentSystem`(텍스처 굽기)도
그대로 쓴다. 렌더 대상이 카드 앞면 → 패널 quad로 바뀔 뿐이다.

---

## 8. 미결정 사항 ❓

**아래 두 가지가 결정되어야 나머지 작업 범위가 확정된다.**

### ① 점수·라이프·클리어 개념을 남길 것인가

"탭하면 설명이 뜬다"만 남으면 이것은 게임이 아니라 **AR 전시물/카탈로그**가 된다.
현재 코드의 상당 부분이 발음 게임 전용이다.

| 남기지 않을 경우 삭제되는 코드 | 줄수 |
|---|---|
| `DetailCardViewModel` (STT/TTS/Levenshtein/무음 감지) | 297 |
| `ARContainerViewController+Score.swift` (점수·라이프·통과 판정) | 69 |
| `GameStatus`, `LifeHeart`, `AudioBand`, `AccuracyType` | ~250 |
| `CompleteWindow`, `FailureWindow` | ~150 |
| `GameSessionModel`, `UsedCardModel` 및 저장 로직 | ~100 |

- **전시물로 간다** → 위 코드 전부 삭제. 대신 "끝나는 조건"을 새로 정의해야 한다
  (예: 5장 모두 열람 시 완료 연출).
- **게임성을 남긴다** → "설명 읽고 → 퀴즈" 형태를 권장. 점수·라이프 구조는 살아남고
  STT/발음 채점만 빠진다.

### ② 카드는 몇 장이고, 책상에 고정인가

`maximumNumberOfTrackedImages`는 기기별 상한이 있다 (통상 4).

- **책상 고정** → "감지 후 앵커 고정"으로 상한을 우회할 수 있어 장수 제한이 사실상 없다.
- **손으로 집어 움직임** → 동시 추적 4장이 상한. 카드 수를 그에 맞춰야 한다.

---

## 9. 리스크

| 리스크 | 영향 | 대응 |
|---|---|---|
| 플랫 로고의 특징점 부족 | 인식 실패 | §4 인쇄 요구사항 준수, 실물로 사전 검증 |
| 부스 조명이 어둡거나 반사 | 인식률 저하 | 무광 인쇄, 부스 조명 조건에서 실측 |
| 카드가 작으면 인식 거리 짧음 | UX 저하 | 트럼프 크기(6.3×8.8cm) 기준 팔 뻗은 거리. 더 크게 인쇄 검토 |
| 동시 추적 상한 | 카드 수 제한 | §8-② 결정에 따라 앵커 고정 방식 채택 |
| 실기기 없이 검증 불가 | 개발 속도 | 시뮬레이터에서 이미지 인식 불가. 실기기 상시 확보 필요 |

---

## 10. 참고 — 기존 코드에서 발견된 문제

전환 과정에서 함께 정리할 것들.

- `GamePhase.paused`는 어디서도 설정되지 않는다. 일시정지는 SwiftUI 오버레이로만
  처리되고 AR 세션은 계속 동작한다.
- `ARContainerViewController+CardPlacement.swift:12`의 `placeCards()`는 `public`이지만
  호출부가 없다 (포탈 경로로 대체된 죽은 코드).
- `WordDetailCard.swift:85`가 `.onChange(of: accuracyPercent)`로 점수를 제출하므로,
  첫 시도가 0%면 값이 바뀌지 않아 제출 자체가 누락된다.
- 발음 실패에도 `isCompleted = true`가 설정되어 재도전이 불가능하다.
- `ARView.swift:44`의 `gameCards`가 computed property + `shuffled()`라 body 재평가마다
  다시 섞인다. `GameSettings`는 최초 1회만 캡처되어 게임에는 영향이 없으나 낭비.
- `handleRemovedAnchors`는 `.scanning`에서만 동작해 `.scanned` 도달 후에는
  평면을 잃어도 카운트가 줄지 않는다.
