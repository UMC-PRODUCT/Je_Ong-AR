# 이미지 인식 AR 전시물 전환 — 실행 계획

> **에이전트로 실행할 경우:** `superpowers:subagent-driven-development` 또는
> `superpowers:executing-plans`로 태스크 단위 실행. 체크박스(`- [ ]`)로 진행을 추적한다.

**목표:** 평면 인식 발음 게임을 실물 카드 9장 이미지 인식 기반 AR 전시물로 전환한다.

**접근:** 기존 `ARCore` 골격을 유지한 채 게임 계층을 기능 슬라이스 단위로 절제하고,
그 자리에 이미지 인식 파이프라인을 세운다. 각 태스크는 **초록 빌드로 끝난다** —
2,394줄을 지우는 작업이라 중간에 빌드가 깨진 채로 다음 태스크로 넘어가면 원인 추적이
불가능해진다.

**기술 스택:** Swift 6.1 / SwiftUI / ARKit / RealityKit / Tuist 4.155.0 / XCTest

**설계 문서:** `Docs/DESIGN.md` — 이 계획은 설계에서 논증을 가져온다. 실행자는 둘 다 읽는다.


---

## 실행 기록 (2026-08-21)

**Task 1~13, 15 완료. Task 14(실기기 검증)만 남았다** — 사람이 인쇄물과 iPad로 해야 한다.

| 페이즈 | 커밋 | 결과 |
|---|---|---|
| A. 안전망 | `5d5011e` `ed0e7a4` `3c6d8e9` | 테스트 타깃 신설, CardSelection·TechCard + 테스트 11개 |
| B. 게임 절제 | `dd2478c` `27eb0d2` `b8ed769` `645b3cc` `03b7691` | 6,483줄 삭제 |
| C. 인식 파이프라인 | `7ade9fc` `2c46560` `4300aa6` `fd47e5e` | 세션 전환 → 앵커 → 탭 → 패널 텍스처 |
| D. 마감 | `(Task 13)` `(Task 15)` | 오버레이 3개, 리네이밍 |

최종 검증: UMCAR·ARCoreDemoApp 양쪽 `BUILD SUCCEEDED`, ARCore 테스트 15개 통과,
`verify_card_content.py` PASS, `verify_ar_resource_group.sh` PASS,
게임 잔재 심볼 검색 0건.

### 계획과 달라진 것

계획서는 태스크를 기능 슬라이스로 잘랐지만, 실제로는 슬라이스 경계가 몇 군데
어긋나 있었다. 모두 "중간 빌드가 깨지지 않게"를 기준으로 조정했다.

- **Task 5를 Task 4보다 먼저 실행.** `WordDetailCard`/`DetailCardViewModel`이
  `AccuracyType`을 소비해서 계획 순서로는 빌드가 깨진 채 커밋해야 했다.
- **`FinishedOverlay`를 Task 7 → Task 4로.** `FailureWindow`를 쓴다.
- **`CardPositioner`를 Task 10 → Task 7로.** `KonglishARProject`와
  `ARFeatureProvider`를 둘 다 참조해 그 슬라이스에 딸려 왔다.
- **`DynamicCardContentSystem`·`CardComponent`를 Task 12에서 삭제.** 계획에 없었다.
  삭제된 usdz 카드 구조(`PlaneFront` 자식)에만 묶여 있어 영원히 매칭되지 않는
  상태였다.
- **`TechCard.logoAssetName`을 Task 8에서 추가.** 설계 §6에 있었는데 Task 3에서
  빠뜨렸고, `GameCard.image`를 대체할 것이 없어 거기서 드러났다.
- **`Tools/verify_card_content.py` 신설.** 계획에 없었다. Task 3의 유닛 테스트는
  id와 빈 값만 보는데, 설계 §6이 위험으로 짚은 것은 본문이 어긋나는 경우다.
  앱이 JSON을 읽지 않으므로 유닛 테스트로는 잡을 수 없어 별도 스크립트로 만들었다.
- **Task 15 범위 축소.** `GameCard`/`GameSettings`/`GamePhase`가 각 슬라이스와
  함께 이미 사라져서 리네이밍이 6개 파일로 끝났다.

### 삽질 기록 (전부 커밋 메시지에도 있다)

- `git rm` 목록에 없는 경로 + `|| 폴백` → 목록 전체가 실패하고 폴백만 실행됐다.
  삭제된 줄 알고 넘어갔다가 grep으로 발견.
- 정규식으로 SwiftUI 조건 분기 제거 → `if`만 지워지고 `else`가 남아 파싱 에러.
- grep으로 삭제 심볼만 훑기 → `SceneEvents.Update` 구독 안의 호출이 안 걸려 빌드 실패.
  심볼을 *부르는* 구독·등록 지점까지 봐야 한다.
- 로고 이미지셋을 카드 id로 등록 → 같은 카탈로그의 AR 레퍼런스 이미지와 이름이 겹쳐
  actool이 "Identical key for two renditions"로 실패. 로고 쪽에 네임스페이스를 줬다.
- `UnlitMaterial`의 `.transparent(opacity: 0)` → 정수 리터럴이라 타입 추론 실패.
- 패널 텍스트를 위에서부터 쌓기 → 설명이 짧은 카드는 하단 40%가 비었다.
  `boundingRect`로 총 높이를 재고 세로 중앙 배치로 변경.

---

## 전역 제약

설계 문서의 프로젝트 전체 요구사항. **모든 태스크의 요구사항에 암묵적으로 포함된다.**

- **배포 타깃**: iOS 18.0, iPad 전용, 가로 방향 고정
- **Tuist**: 이 머신에서 `tuist`는 PATH에 없다. 항상 `mise exec tuist@4.155.0 -- tuist ...`
- **프로젝트 생성**: `cd UMCAR && mise exec tuist@4.155.0 -- tuist generate --no-open`
- **빌드 확인** (모든 태스크 필수):
  ```bash
  cd UMCAR && xcodebuild -workspace UMCAR.xcworkspace -scheme UMCAR \
    -destination 'generic/platform=iOS' -configuration Debug build \
    CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|^\*\*" | sort -u
  ```
  기대: `** BUILD SUCCEEDED **`, `error:` 0건
- **테스트 실행**:
  ```bash
  cd UMCAR && xcodebuild test -workspace UMCAR.xcworkspace -scheme UMCAR \
    -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' 2>&1 | grep -E "Executed|error:"
  ```
- **데모 앱 빌드**: `cd ARCoreDemoApp && xcodebuild -workspace ARCoreDemoApp.xcworkspace -scheme ARCoreDemoApp -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO`
- **카드 실측 크기**: `90 × 127 mm` (= `0.09, 0.13 m`)
- **AR Resource Group 이름**: `TechCards`
- **`.arreferenceimage`의 `unit`**: `centimeters` 만 유효. `millimeters`는 **에러 없이**
  물리 크기를 `0.01,0.01`로 떨어뜨린다 (`DESIGN.md` §9)
- **레퍼런스 이미지 이름 == `TechCard.id`** (`corelocation`, `apple-intelligence`,
  `cloudkit`, `coreml`, `foundation-models`, `liquid-glass`, `sirikit`,
  `nearby-interaction`, `widgetkit`)
- **시뮬레이터에서 ARKit 이미지 인식은 불가.** AR 동작 검증은 실기기 전용
- **커밋 컨벤션**: `[태그] - 제목` + 본문(변경 사항 / 영향 범위 / **버린 접근**).
  버린 접근은 있었으면 반드시 적는다
- **브랜치**: `feature/reference-cards` (이미 생성됨)

---

## 파일 구조

### 신규

| 파일 | 책임 |
|---|---|
| `ARCore/Sources/Data/TechCard.swift` | 카드 콘텐츠 값 타입 + `TechCard.all` 9장 |
| `ARCore/Sources/Data/CardSelection.swift` | 탭 선택 규칙 (순수 값 타입, 테스트 대상) |
| `ARCore/Sources/Data/ExhibitSettings.swift` | 앱이 주입하는 설정 (카드 + 레퍼런스 이미지 + 폰트) |
| `ARCore/Sources/Data/ExhibitPhase.swift` | 3단계 상태 (`GamePhase` 대체) |
| `ARCore/Sources/Components/TechCardComponent.swift` | 엔티티에 카드 id를 붙이는 컴포넌트 |
| `ARCore/Sources/UIComponents/ARContainerViewController+ImageDetection.swift` | 앵커 감지 → 씬 부착 |
| `ARCore/Sources/UIComponents/ARContainerViewController+Tap.swift` | 탭 → 선택 → 패널 토글 |
| `ARCore/Sources/Features/AR/CardPanelBuilder.swift` | 콜라이더 판 + 패널 quad 생성 |
| `ARCore/Tests/**` | ARCore 유닛 테스트 (타깃 신설) |
| `UMCAR/Sources/Presentation/Overlay/Views/ScanGuideOverlay.swift` | "카드를 비춰주세요" + n/9 |
| `UMCAR/Sources/Presentation/Overlay/Views/BrowsingOverlay.swift` | 최소 구성 (종료, 인식 수) |

### 대폭 수정

| 파일 | 작업 |
|---|---|
| `ARCore/Sources/UIComponents/ARContainerViewController.swift` | 게임 상태 프로퍼티 제거 |
| `ARCore/Sources/UIComponents/ARContainerViewController+ARSetup.swift:54` | `planeDetection` → `detectionImages` |
| `ARCore/Sources/UIComponents/ARContainer.swift` | 바인딩 13개 → 4개 |
| `ARCore/Sources/UIComponents/ARContainerViewControllerDelegate.swift` | 5개 → 3개 |
| `ARCore/Sources/Features/AR/CardDetector.swift` | 중앙 조준 → 탭 좌표 |
| `ARCore/Sources/Features/DynamicTexture/CardContentImageWriter.swift:76` | 패널 레이아웃 |
| `UMCAR/Sources/Presentation/AR/Views/ARView.swift` | SwiftData 제거, 오버레이 축소 |
| `UMCAR/Sources/Presentation/AR/ViewModels/ARViewModel.swift` | 게임 프로퍼티 제거 |
| `UMCAR/Sources/UMCARApp.swift` | ModelContainer 제거 |

### 삭제 (2,394줄)

`DESIGN.md` §10의 표 그대로.

---

## 페이즈 개요

| 페이즈 | 태스크 | 끝났을 때 |
|---|---|---|
| **A. 안전망** | 1–3 | 새 순수 로직이 테스트와 함께 존재. 기존 동작 그대로 |
| **B. 게임 절제** | 4–8 | 게임 코드 2,394줄 삭제. 앱은 평면 스캔까지만 동작 |
| **C. 인식 파이프라인** | 9–12 | 카드 9장 인식 → 탭 → 패널. 실기기에서 동작 |
| **D. 마감** | 13–15 | 오버레이 정리, 실기기 검증, 리네이밍 |

각 태스크는 커밋으로 끝난다.

---

# 페이즈 A — 안전망

기존 코드를 건드리지 않고 **추가만** 한다. 빌드가 깨질 수 없는 구간이다.

## Task 1: ARCore 테스트 타깃 신설

`ARCore`에는 테스트 타깃이 없다. 이후 태스크의 순수 로직을 검증할 곳을 먼저 만든다.

**Files:**
- Modify: `UMCAR/ARCore/Project.swift`
- Create: `UMCAR/ARCore/Tests/ARCoreTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces: `ARCoreTests` 타깃. 이후 모든 ARCore 유닛 테스트가 여기 들어간다

- [ ] **Step 1: 테스트 타깃을 추가한다**

`UMCAR/ARCore/Project.swift`의 `targets:` 배열에 두 번째 타깃을 추가한다.

```swift
        .target(name: "ARCore",
                destinations: .iOS,
                product: .staticFramework,
                bundleId: "app.arCore.UMCAR",
                deploymentTargets: .iOS("18.0"),
                infoPlist: .default,
                sources: ["Sources/**"],
                resources: ["Resources/**"],
                dependencies: [.package(product: "KonglishARProject")]
        ),
        .target(name: "ARCoreTests",
                destinations: .iOS,
                product: .unitTests,
                bundleId: "app.arCoreTests.UMCAR",
                deploymentTargets: .iOS("18.0"),
                infoPlist: .default,
                sources: ["Tests/**"],
                resources: [],
                dependencies: [.target(name: "ARCore")]
        )
```

- [ ] **Step 2: 타깃이 살아 있는지 확인할 최소 테스트를 쓴다**

`UMCAR/ARCore/Tests/ARCoreTests.swift`:

```swift
import XCTest
@testable import ARCore

final class ARCoreTests: XCTestCase {
    /// 타깃 배선 확인용. Task 2에서 실제 테스트로 대체된다.
    func test_targetIsWired() {
        XCTAssertTrue(true)
    }
}
```

- [ ] **Step 3: 프로젝트를 다시 생성하고 테스트가 도는지 확인한다**

```bash
cd UMCAR && mise exec tuist@4.155.0 -- tuist generate --no-open
xcodebuild test -workspace UMCAR.xcworkspace -scheme ARCore \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' 2>&1 | grep -E "Executed|error:"
```

기대: `Executed 1 test, with 0 failures`

- [ ] **Step 4: 커밋**

```bash
git add UMCAR/ARCore/Project.swift UMCAR/ARCore/Tests
git commit -m "[Test] - ARCore 유닛 테스트 타깃 신설

변경 사항:
- ARCore/Project.swift에 ARCoreTests 타깃 추가
- ARCore/Tests/ARCoreTests.swift — 배선 확인용 최소 테스트

왜 필요한가: ARCore에 테스트 타깃이 없었다. 전환 과정에서 만들 순수 로직
(CardSelection, TechCard 무결성)은 시뮬레이터에서 검증 가능한 유일한 조각이라
검증할 곳을 먼저 만든다.

영향 범위: 기존 코드 변경 없음. 타깃 추가만."
```

---

## Task 2: CardSelection — 탭 선택 규칙

설계 §5의 선택 규칙을 ARKit 의존 없는 값 타입으로 분리한다. **실기기 없이 검증 가능한
유일한 로직**이라 반드시 떼어낸다.

**Files:**
- Create: `UMCAR/ARCore/Sources/Data/CardSelection.swift`
- Test: `UMCAR/ARCore/Tests/CardSelectionTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces:
  - `public struct CardSelection: Equatable`
  - `public private(set) var selected: String?`
  - `public mutating func tap(_ cardID: String?) -> Change`
  - `public enum Change: Equatable { case opened(String), closed(String), replaced(from: String, to: String), unchanged }`

  Task 11(탭 결선)이 `Change`를 보고 패널 엔티티를 켜고 끈다.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`UMCAR/ARCore/Tests/CardSelectionTests.swift`:

```swift
import XCTest
@testable import ARCore

final class CardSelectionTests: XCTestCase {
    func test_초기에는_선택된_카드가_없다() {
        let selection = CardSelection()
        XCTAssertNil(selection.selected)
    }

    func test_카드를_탭하면_열린다() {
        var selection = CardSelection()
        let change = selection.tap("coreml")
        XCTAssertEqual(selection.selected, "coreml")
        XCTAssertEqual(change, .opened("coreml"))
    }

    func test_같은_카드를_다시_탭하면_닫힌다() {
        var selection = CardSelection()
        _ = selection.tap("coreml")
        let change = selection.tap("coreml")
        XCTAssertNil(selection.selected)
        XCTAssertEqual(change, .closed("coreml"))
    }

    func test_다른_카드를_탭하면_교체된다() {
        var selection = CardSelection()
        _ = selection.tap("coreml")
        let change = selection.tap("sirikit")
        XCTAssertEqual(selection.selected, "sirikit")
        XCTAssertEqual(change, .replaced(from: "coreml", to: "sirikit"))
    }

    func test_빈_곳을_탭하면_열린_카드가_닫힌다() {
        var selection = CardSelection()
        _ = selection.tap("coreml")
        let change = selection.tap(nil)
        XCTAssertNil(selection.selected)
        XCTAssertEqual(change, .closed("coreml"))
    }

    func test_아무것도_안_열린_상태에서_빈_곳_탭은_아무_일도_없다() {
        var selection = CardSelection()
        let change = selection.tap(nil)
        XCTAssertNil(selection.selected)
        XCTAssertEqual(change, .unchanged)
    }
}
```

- [ ] **Step 2: 테스트가 실패하는지 확인한다**

```bash
cd UMCAR && xcodebuild test -workspace UMCAR.xcworkspace -scheme ARCore \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' 2>&1 | grep -E "error:|Executed"
```

기대: `cannot find 'CardSelection' in scope` 컴파일 에러

- [ ] **Step 3: 최소 구현을 쓴다**

`UMCAR/ARCore/Sources/Data/CardSelection.swift`:

```swift
//
//  CardSelection.swift
//  ARCore
//

import Foundation

/// 카드 탭에 따른 선택 상태.
///
/// 패널은 한 번에 한 장만 뜬다. 관람객이 "지금 무엇을 보고 있는지" 헷갈리지 않게
/// 하려는 것이고, 덕분에 상태가 선택된 카드 id 하나로 끝난다.
///
/// ARKit·RealityKit 의존이 없다. 실기기 없이 검증 가능한 유일한 로직이라 일부러
/// 값 타입으로 떼어냈다.
public struct CardSelection: Equatable {
    /// 선택에 따라 무엇이 바뀌었는지. 호출부가 이걸 보고 패널 엔티티를 켜고 끈다.
    public enum Change: Equatable {
        case opened(String)
        case closed(String)
        case replaced(from: String, to: String)
        case unchanged
    }

    public private(set) var selected: String?

    public init() {}

    /// 카드를 탭한다. `nil`은 빈 곳을 탭했다는 뜻이다.
    @discardableResult
    public mutating func tap(_ cardID: String?) -> Change {
        switch (selected, cardID) {
        case (nil, nil):
            return .unchanged
        case let (previous?, nil):
            selected = nil
            return .closed(previous)
        case let (nil, tapped?):
            selected = tapped
            return .opened(tapped)
        case let (previous?, tapped?) where previous == tapped:
            selected = nil
            return .closed(previous)
        case let (previous?, tapped?):
            selected = tapped
            return .replaced(from: previous, to: tapped)
        }
    }
}
```

- [ ] **Step 4: 테스트가 통과하는지 확인한다**

```bash
cd UMCAR && xcodebuild test -workspace UMCAR.xcworkspace -scheme ARCore \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' 2>&1 | grep -E "Executed|error:"
```

기대: `Executed 7 tests, with 0 failures` (Task 1의 배선 테스트 1개 포함)

- [ ] **Step 5: 커밋**

```bash
git add UMCAR/ARCore/Sources/Data/CardSelection.swift UMCAR/ARCore/Tests/CardSelectionTests.swift
git commit -m "[Feat] - 카드 탭 선택 규칙을 순수 값 타입으로 분리

변경 사항:
- ARCore/Sources/Data/CardSelection.swift — 열기/닫기/교체 토글 규칙
- 테스트 6개: 초기 상태, 열기, 같은 카드 토글, 다른 카드 교체, 빈 곳 탭, 무변화

왜 값 타입인가: ARKit·RealityKit 의존이 없어 시뮬레이터에서 검증된다.
실기기 없이 검증 가능한 유일한 로직 조각이라 일부러 떼어냈다 (DESIGN.md §5, §11).

영향 범위: 추가만. 아직 호출부 없음."
```

---

## Task 3: TechCard — 카드 콘텐츠 데이터

SwiftData 모델 5개를 대체할 Swift 배열 상수. 무결성 테스트가 레퍼런스 이미지 이름과의
1:1 대응을 지킨다.

**Files:**
- Create: `UMCAR/ARCore/Sources/Data/TechCard.swift`
- Test: `UMCAR/ARCore/Tests/TechCardTests.swift`
- 참조 (읽기만): `Docs/Assets/ReferenceCards/cards/cards.json`

**Interfaces:**
- Consumes: 없음
- Produces:
  - `public struct TechCard: Identifiable, Hashable` — `id` `name` `tag` `summary` `detail`
  - `public static let all: [TechCard]` (9장, `cards.json` 순서)
  - `public static func card(id: String) -> TechCard?`

  Task 9(설정 주입), Task 10(앵커 → 카드 조회), Task 12(패널 텍스처)가 쓴다.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`UMCAR/ARCore/Tests/TechCardTests.swift`:

```swift
import XCTest
@testable import ARCore

final class TechCardTests: XCTestCase {
    /// 레퍼런스 이미지 이름과 1:1로 맞아야 한다. 어긋나면 인식은 되는데 조회가 실패한다.
    private let expectedIDs = [
        "corelocation", "apple-intelligence", "cloudkit", "coreml",
        "foundation-models", "liquid-glass", "sirikit",
        "nearby-interaction", "widgetkit",
    ]

    func test_카드는_9장이다() {
        XCTAssertEqual(TechCard.all.count, 9)
    }

    func test_id가_레퍼런스_이미지_이름과_일치한다() {
        XCTAssertEqual(Set(TechCard.all.map(\.id)), Set(expectedIDs))
    }

    func test_id에_중복이_없다() {
        XCTAssertEqual(Set(TechCard.all.map(\.id)).count, TechCard.all.count)
    }

    func test_모든_카드에_내용이_채워져_있다() {
        for card in TechCard.all {
            XCTAssertFalse(card.name.isEmpty, "\(card.id): name 비어 있음")
            XCTAssertFalse(card.tag.isEmpty, "\(card.id): tag 비어 있음")
            XCTAssertFalse(card.summary.isEmpty, "\(card.id): summary 비어 있음")
            XCTAssertFalse(card.detail.isEmpty, "\(card.id): detail 비어 있음")
        }
    }

    func test_id로_카드를_찾는다() {
        XCTAssertEqual(TechCard.card(id: "coreml")?.name, "CoreML")
        XCTAssertNil(TechCard.card(id: "없는카드"))
    }
}
```

- [ ] **Step 2: 테스트가 실패하는지 확인한다**

```bash
cd UMCAR && xcodebuild test -workspace UMCAR.xcworkspace -scheme ARCore \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' 2>&1 | grep -E "error:|Executed"
```

기대: `cannot find 'TechCard' in scope`

- [ ] **Step 3: 구현을 쓴다**

`UMCAR/ARCore/Sources/Data/TechCard.swift` — 내용은
`Docs/Assets/ReferenceCards/cards/cards.json`과 **글자 그대로 같아야 한다.**
어긋나면 카드 뒷면과 패널 내용이 따로 논다 (DESIGN.md §6).

```swift
//
//  TechCard.swift
//  ARCore
//

import Foundation

/// 카드 한 장의 콘텐츠.
///
/// `id`가 곧 `ARReferenceImage.name`이다. 그래서 앵커 → 카드 조회가 한 줄로 끝난다.
public struct TechCard: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let tag: String
    public let summary: String
    public let detail: String

    public init(id: String, name: String, tag: String, summary: String, detail: String) {
        self.id = id
        self.name = name
        self.tag = tag
        self.summary = summary
        self.detail = detail
    }
}

public extension TechCard {
    static func card(id: String) -> TechCard? {
        all.first { $0.id == id }
    }

    /// 부스에 배치하는 9장.
    ///
    /// 원본은 `Tools/gen_reference_cards.py`의 CARDS 배열이고 카드 이미지와
    /// `cards.json`이 거기서 함께 생성된다. 여기는 그 사본이므로 콘텐츠가 바뀌면
    /// 양쪽을 함께 고쳐야 한다. TechCardTests가 id 대응을 지킨다.
    static let all: [TechCard] = [
        .init(
            id: "corelocation", name: "CoreLocation", tag: "위치·방향",
            summary: "기기가 지금 어디 있는지 알려주는 프레임워크",
            detail: "GPS·Wi-Fi·셀룰러·기압계를 조합해 위·경도, 고도, 나침반 방위를 제공한다. "
                  + "특정 구역 진입/이탈 감지(지오펜싱)와 iBeacon도 여기에 포함된다."
        ),
        .init(
            id: "apple-intelligence", name: "Apple Intelligence", tag: "온디바이스 개인 지능",
            summary: "기기 안에서 동작하는 Apple의 AI 시스템",
            detail: "글쓰기 도구, Genmoji, 알림 요약, Siri를 하나로 묶는다. 대부분 기기 안에서 "
                  + "처리하고, 큰 연산만 Private Cloud Compute로 넘겨 프라이버시를 지킨다."
        ),
        .init(
            id: "cloudkit", name: "CloudKit", tag: "iCloud 동기화",
            summary: "서버를 만들지 않고 데이터를 기기 간에 동기화",
            detail: "사용자의 iCloud 계정에 데이터를 저장해 아이폰·아이패드·맥이 같은 내용을 "
                  + "보게 한다. 비공개·공유·공개 3가지 저장소를 제공한다."
        ),
        .init(
            id: "coreml", name: "CoreML", tag: "온디바이스 머신러닝",
            summary: "학습된 AI 모델을 앱 안에서 직접 실행",
            detail: "모델 파일을 Xcode에 넣으면 Swift 코드가 자동 생성된다. CPU·GPU·Neural "
                  + "Engine에 연산을 알아서 나눠 서버 없이 빠르게 추론한다."
        ),
        .init(
            id: "foundation-models", name: "Foundation Models", tag: "내장 LLM · iOS 26",
            summary: "Apple의 온디바이스 언어 모델을 코드로 호출",
            detail: "Apple Intelligence의 약 30억 파라미터 모델에 직접 프롬프트를 보낸다. "
                  + "오프라인·무료로 동작하고, Swift 타입을 지정하면 그 구조 그대로 결과를 받는다."
        ),
        .init(
            id: "liquid-glass", name: "Liquid Glass", tag: "iOS 26 디자인",
            summary: "빛을 굴절시키는 유리 재질의 새 인터페이스",
            detail: "콘텐츠 위에 떠 있는 유리 레이어가 배경을 굴절·반사하고, 스크롤과 터치에 "
                  + "반응해 모양이 변한다. 툴바·탭바·시트에 자동 적용된다."
        ),
        .init(
            id: "sirikit", name: "SiriKit", tag: "음성·단축어 연동",
            summary: "앱의 기능을 Siri와 단축어에 노출",
            detail: "앱이 할 수 있는 동작을 시스템에 등록하면 음성 명령, 단축어, 잠금 화면, "
                  + "액션 버튼에서 앱을 열지 않고 실행할 수 있다."
        ),
        .init(
            id: "nearby-interaction", name: "Nearby Interaction", tag: "초광대역 정밀 측위",
            summary: "근처 기기까지의 거리와 방향을 센티미터 단위로",
            detail: "U1/U2 칩의 UWB 신호로 상대 기기가 얼마나 멀리, 어느 쪽에 있는지 측정한다. "
                  + "AirTag 정밀 탐색이 이 기술이다."
        ),
        .init(
            id: "widgetkit", name: "WidgetKit", tag: "위젯·라이브 액티비티",
            summary: "앱을 열지 않고 홈 화면에서 정보를 보여주는 방법",
            detail: "홈·잠금·대기 화면과 Watch 위젯, 실시간 진행 상황(라이브 액티비티)을 "
                  + "SwiftUI로 만든다. 시스템이 미리 만든 화면을 대신 그려 배터리를 아낀다."
        ),
    ]
}
```

- [ ] **Step 4: 테스트가 통과하는지 확인한다**

```bash
cd UMCAR && xcodebuild test -workspace UMCAR.xcworkspace -scheme ARCore \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' 2>&1 | grep -E "Executed|error:"
```

기대: `Executed 12 tests, with 0 failures`

- [ ] **Step 5: 커밋**

```bash
git add UMCAR/ARCore/Sources/Data/TechCard.swift UMCAR/ARCore/Tests/TechCardTests.swift
git commit -m "[Feat] - 카드 콘텐츠를 Swift 배열 상수로 추가

변경 사항:
- ARCore/Sources/Data/TechCard.swift — 9장의 id/name/tag/summary/detail
- 무결성 테스트 5개: 9장, id 대응, 중복 없음, 내용 채워짐, 조회

왜 JSON이 아닌가: 런타임 파싱은 부스에서 실패할 경로를 만든다. 9장 고정
콘텐츠라 컴파일 타임 검증이 낫다 (DESIGN.md §6).

이중화 주의: 원본은 Tools/gen_reference_cards.py의 CARDS다. 여기는 사본이므로
콘텐츠 변경 시 양쪽을 함께 고쳐야 하고, TechCardTests가 id 대응을 지킨다.

영향 범위: 추가만. SwiftData 모델은 아직 살아 있다 (Task 8에서 제거)."
```

---

# 페이즈 B — 게임 절제

**여기서 2,394줄이 사라진다.** 기능 슬라이스 단위로 자른다 — 한 태스크가 `ARCore`와
앱 계층을 함께 건드려야 빌드가 초록으로 끝난다. 레이어별로 자르면 중간이 계속 깨진다.

각 태스크의 마지막 단계는 항상 **빌드 확인 → 커밋**이다.

## Task 4: 점수·라이프 슬라이스 제거

**Files:**
- Delete: `ARCore/Sources/UIComponents/ARContainerViewController+Score.swift` (69줄)
- Delete: `ARCore/Sources/Data/GameCardSubmission.swift` (15줄)
- Delete: `UMCAR/Sources/Common/UIComponents/AR/GameStatus.swift` (95줄)
- Delete: `UMCAR/Sources/Common/UIComponents/AR/LifeHeart.swift` (45줄)
- Delete: `UMCAR/Sources/Common/UIComponents/AR/CompleteWindow.swift` (75줄)
- Delete: `UMCAR/Sources/Common/UIComponents/AR/FailureWindow.swift` (72줄)
- Delete: `UMCAR/Sources/Common/Enum/AR/AccuracyType.swift` (76줄)
- Modify: `ARCore/Sources/UIComponents/ARContainerViewController.swift`
- Modify: `ARCore/Sources/UIComponents/ARContainerViewControllerDelegate.swift`
- Modify: `ARCore/Sources/UIComponents/ARContainer.swift`
- Modify: `UMCAR/Sources/Presentation/AR/ViewModels/ARViewModel.swift`
- Modify: `UMCAR/Sources/Presentation/AR/Views/ARView.swift`
- Modify: `ARCoreDemoApp/ARCoreDemoApp/Sources/ContentView.swift`

**Interfaces:**
- Consumes: 없음
- Produces: `ARContainer`에서 `currentLifeCounts` `currentGameScore` `numberOfFinishedCards`
  `cardSubmissions` `triggerSubmitAccuracy` 바인딩이 사라진다. 델리게이트에서
  `didChangeLifeCount` `didChangeScore`가 사라진다.

- [ ] **Step 1: ARCore에서 점수 계층을 지운다**

```bash
git rm UMCAR/ARCore/Sources/UIComponents/ARContainerViewController+Score.swift
git rm UMCAR/ARCore/Sources/Data/GameCardSubmission.swift
```

`ARContainerViewController.swift`에서 다음을 제거한다:
- `static let maxLifeCounts = 5` (17행)
- `var gameCardToAccuracy: [GameCard: Float?]` (54행) 및 `init` 안의 초기화 루프 (100–102행)
- `var reaminLifeCounts` 프로퍼티 전체 (68–75행)
- `public var numberOfFinishedCards: Int` (77–79행)
- `public var currentScore: Int` (82–88행)
- `init`의 `self.gameCardToAccuracy = [:]` (93행)

`ARContainerViewControllerDelegate.swift`에서 `didChangeLifeCount`, `didChangeScore` 선언을 제거한다.

- [ ] **Step 2: ARContainer에서 관련 바인딩과 Coordinator 메서드를 지운다**

`ARContainer.swift`에서 제거:
- `@Binding var currentLifeCounts: Int`, `currentGameScore`, `numberOfFinishedCards`,
  `cardSubmissions`, `triggerSubmitAccuracy` 프로퍼티와 `init` 파라미터·대입
- `updateUIViewController`의 `if let triggerSubmitAccuracy = ...` 블록 전체 (121–136행)
- `Coordinator`의 `didChangeLifeCount`, `didChangeScore` 메서드 (175–195행)

- [ ] **Step 3: 앱 계층에서 점수 UI를 지운다**

```bash
git rm UMCAR/UMCAR/Sources/Common/UIComponents/AR/GameStatus.swift
git rm UMCAR/UMCAR/Sources/Common/UIComponents/AR/LifeHeart.swift
git rm UMCAR/UMCAR/Sources/Common/UIComponents/AR/CompleteWindow.swift
git rm UMCAR/UMCAR/Sources/Common/UIComponents/AR/FailureWindow.swift
git rm UMCAR/UMCAR/Sources/Common/Enum/AR/AccuracyType.swift
```

`ARViewModel.swift`에서 `currentLifeCounts`, `currentGameScore`, `numberOfFinishedCards`,
`cardSubmissions`, `triggerSubmitAccuracy` 제거.

`ARView.swift`에서 해당 바인딩 전달 제거, `saveScore()`/`saveSuccessCount()` 및 이를 부르는
`.onChange(of: arViewModel.numberOfFinishedCards)` 제거, `.onChange(of: cardSubmissions)` 제거.

`ARCoreDemoApp/ContentView.swift`에서 해당 `@State`·바인딩·"단어 정답 제출" 버튼 2개 제거.

- [ ] **Step 4: 두 앱 모두 빌드되는지 확인한다**

```bash
cd UMCAR && xcodebuild -workspace UMCAR.xcworkspace -scheme UMCAR \
  -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|^\*\*" | sort -u
cd ../ARCoreDemoApp && xcodebuild -workspace ARCoreDemoApp.xcworkspace -scheme ARCoreDemoApp \
  -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|^\*\*" | sort -u
```

기대: 둘 다 `** BUILD SUCCEEDED **`

> 참고: `WordDetailCard.swift`가 `AccuracyType`을 참조한다. 이 태스크에서 컴파일 에러가
> 나면 Task 5의 삭제 대상이므로, 여기서는 해당 참조만 임시로 걷어내지 말고
> **Task 5와 묶어서 진행해도 된다.** 다만 커밋은 슬라이스별로 나눈다.

- [ ] **Step 5: 커밋**

```bash
git add -A
git commit -m "[Refactor] - 점수·라이프 계층 제거

전시물에는 점수와 라이프가 없다 (DESIGN.md §2).

변경 사항:
- ARCore: +Score.swift, GameCardSubmission.swift 삭제.
  ARContainerViewController에서 gameCardToAccuracy/reaminLifeCounts/currentScore/
  numberOfFinishedCards 제거. 델리게이트 didChangeLifeCount/didChangeScore 제거.
- ARContainer: 바인딩 5개(currentLifeCounts, currentGameScore, numberOfFinishedCards,
  cardSubmissions, triggerSubmitAccuracy)와 Coordinator 메서드 2개 제거
- 앱: GameStatus, LifeHeart, CompleteWindow, FailureWindow, AccuracyType 삭제.
  ARView의 saveScore/saveSuccessCount 제거
- 데모앱: 점수 제출 버튼 제거

같이 정리된 문제: Score.swift:30이 통과/실패 무관하게 isCompleted=true를 박아
한 번 틀리면 카드를 다시 뒤집을 수 없던 버그가 코드째 사라졌다 (DESIGN.md §13).

영향 범위: UMCAR·ARCoreDemoApp 양쪽 빌드 확인 완료."
```

---

## Task 5: 발음·STT 슬라이스 제거

**Files:**
- Delete: `UMCAR/Sources/Presentation/AR/ViewModels/DetailCardViewModel.swift` (297줄)
- Delete: `UMCAR/Sources/Common/UIComponents/AR/WordDetailCard.swift` (221줄)
- Delete: `UMCAR/Sources/Common/UIComponents/AR/AudioBand.swift` (67줄)
- Delete: `UMCAR/Sources/Presentation/Overlay/Views/OnShowingCardOverlay.swift` (80줄)
- Modify: `UMCAR/Sources/Presentation/AR/Views/ARView.swift`
- Modify: `UMCAR/Project.swift` — 마이크·음성인식 권한 문구 제거

- [ ] **Step 1: 발음 관련 파일을 지운다**

```bash
git rm UMCAR/UMCAR/Sources/Presentation/AR/ViewModels/DetailCardViewModel.swift
git rm UMCAR/UMCAR/Sources/Common/UIComponents/AR/WordDetailCard.swift
git rm UMCAR/UMCAR/Sources/Common/UIComponents/AR/AudioBand.swift
git rm UMCAR/UMCAR/Sources/Presentation/Overlay/Views/OnShowingCardOverlay.swift
```

- [ ] **Step 2: ARView에서 참조를 걷어낸다**

`ARView.swift`에서 제거:
- `@State var detailCardViewModel: DetailCardViewModel = .init()` (51행)
- 오버레이 `switch`의 `OnShowingCardOverlay` 분기 (96–99행)
- `.onChange(of: arViewModel.flippedCardId)` 블록 (109–113행)
- `.onChange(of: arViewModel.showingWordDetailCard)` 블록 (122–129행)

`ARViewModel.swift`에서 `showingWordDetailCard`, `cardShowingTimeOffset`,
`closeCardButtonTapped()` 제거.

- [ ] **Step 3: 더 이상 쓰지 않는 권한 문구를 Info.plist에서 뺀다**

`UMCAR/Project.swift`의 `infoPlist`에서 두 줄을 제거한다. 쓰지 않는 권한을 남겨두면
심사와 사용자 신뢰 양쪽에 불필요한 마찰이 된다.

```swift
                    "NSMicrophoneUsageDescription": "발음 분석을 위해 마이크 사용이 필요합니다",
                    "NSSpeechRecognitionUsageDescription": "발음 분석을 위해 음성 인식이 필요합니다",
```

- [ ] **Step 4: 프로젝트 재생성 후 빌드 확인**

```bash
cd UMCAR && mise exec tuist@4.155.0 -- tuist generate --no-open
xcodebuild -workspace UMCAR.xcworkspace -scheme UMCAR \
  -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|^\*\*" | sort -u
```

기대: `** BUILD SUCCEEDED **`

- [ ] **Step 5: 커밋**

```bash
git add -A
git commit -m "[Refactor] - 발음 채점(STT/TTS) 계층 제거

전시물은 발음을 채점하지 않는다 (DESIGN.md §2).

변경 사항:
- DetailCardViewModel(297줄), WordDetailCard(221줄), AudioBand,
  OnShowingCardOverlay 삭제
- ARView/ARViewModel에서 단어 상세 카드 표시 경로 제거
- Info.plist에서 NSMicrophoneUsageDescription,
  NSSpeechRecognitionUsageDescription 제거 — 쓰지 않는 권한을 남기지 않는다

같이 정리된 문제: WordDetailCard.swift:84가 onChange(of: accuracyPercent)로
점수를 제출해 첫 시도가 0%면 제출이 누락되던 버그가 코드째 사라졌다 (DESIGN.md §13).

영향 범위: Info.plist 변경으로 tuist generate 필요. 빌드 확인 완료."
```

---

## Task 6: 뒤집기·조준 슬라이스 제거

**Files:**
- Delete: `ARCore/Sources/UIComponents/ARContainerViewController+CardFlipper.swift` (36줄)
- Delete: `ARCore/Sources/Features/AR/CardRotator.swift` (80줄)
- Delete: `ARCore/Sources/UIComponents/ARContainerViewController+Hover.swift` (38줄)
- Delete: `ARCore/Sources/System/HoverSystem.swift` (34줄)
- Delete: `ARCore/Sources/Components/HoverComponent.swift` (47줄)
- Modify: `ARCore/Sources/UIComponents/ARContainerViewController.swift`
- Modify: `ARCore/Sources/UIComponents/ARContainer.swift`
- Modify: `UMCAR/Sources/Presentation/Overlay/Views/PlayingGameOverlay.swift`
- Modify: `UMCAR/Sources/Presentation/AR/ViewModels/ARViewModel.swift`
- Modify: `ARCoreDemoApp/ARCoreDemoApp/Sources/ContentView.swift`

- [ ] **Step 1: 파일을 지운다**

```bash
git rm UMCAR/ARCore/Sources/UIComponents/ARContainerViewController+CardFlipper.swift
git rm UMCAR/ARCore/Sources/Features/AR/CardRotator.swift
git rm UMCAR/ARCore/Sources/UIComponents/ARContainerViewController+Hover.swift
git rm UMCAR/ARCore/Sources/System/HoverSystem.swift
git rm UMCAR/ARCore/Sources/Components/HoverComponent.swift
```

- [ ] **Step 2: 참조를 걷어낸다**

`ARContainerViewController.swift`: `var cardRotator: CardRotator?`,
`var observeHoveringAccumulatedTime: TimeInterval = 0` 제거.
`+ARSetup.swift`의 프로바이더 초기화에서 `cardRotator` 관련 줄 제거.

`ARContainer.swift`: `@Binding var triggerFlipCard`, `@Binding var flippedCardId`와
`init` 파라미터, `updateUIViewController`의 `if triggerFlipCard` 블록(138–145행) 제거.

`PlayingGameOverlay.swift`: 좌우 `targetBtn` 오버레이 2개(39–46행), 조준점
`Image(.aim)` 오버레이(47–49행), `private var targetBtn` 정의(58–62행) 제거.

`ARViewModel.swift`: `triggerFlipCard`, `flippedCardId`, `flipCardButtonTapped()` 제거.

`ARCoreDemoApp/ContentView.swift`: "카드 뒤집기" 버튼과 관련 `@State` 제거.

- [ ] **Step 3: 두 앱 빌드 확인**

전역 제약의 빌드 명령 두 개를 모두 실행한다. 기대: 둘 다 `** BUILD SUCCEEDED **`

- [ ] **Step 4: 커밋**

```bash
git add -A
git commit -m "[Refactor] - 카드 뒤집기·중앙 조준 제거

실물 카드는 사람이 손으로 뒤집는다. 돌릴 가상 3D 카드가 없고, 카드를 직접
터치하므로 조준 개념도 사라진다 (DESIGN.md §2, §7).

변경 사항:
- ARCore: +CardFlipper, CardRotator, +Hover, HoverSystem, HoverComponent 삭제
- ARContainer: triggerFlipCard, flippedCardId 바인딩 제거
- 앱: PlayingGameOverlay의 조준점 Image(.aim)과 좌우 targetBtn 2개 제거
- 데모앱: 카드 뒤집기 버튼 제거

영향 범위: UMCAR·ARCoreDemoApp 양쪽 빌드 확인 완료."
```

---

## Task 7: 포탈·카드 배치·평면 감지 제거

여기서 `GamePhase`가 3단계로 줄고 usdz 패키지가 빠진다.

**Files:**
- Delete: `ARCore/Sources/UIComponents/ARContainerViewController+Portal.swift` (127줄)
- Delete: `ARCore/Sources/Features/AR/CentralPortalVisualizer.swift` (149줄)
- Delete: `ARCore/Sources/UIComponents/ARContainerViewController+CardPlacement.swift` (136줄)
- Delete: `ARCore/Sources/UIComponents/ARContainerViewController+PlaneDetection.swift` (131줄)
- Delete: `ARCore/Sources/Features/AR/PlaneVisualizer.swift` (82줄)
- Delete: `ARCore/Sources/Features/AR/ARFeatureProvider.swift` (21줄)
- Delete: `ARCore/Packages/KonglishARProject/**` (11개 파일)
- Delete: `UMCAR/Sources/Presentation/Overlay/Views/FinishedOverlay.swift` (34줄)
- Create: `ARCore/Sources/Data/ExhibitPhase.swift`
- Delete: `ARCore/Sources/Data/GamePhase.swift`
- Modify: `ARCore/Project.swift` — 패키지 의존 제거
- Modify: `ARCore/Sources/Data/GameSettings.swift` — `minimumSizeOfPlane` 제거
- Modify: `ARCore/Sources/UIComponents/ARContainerViewController.swift`
- Modify: `ARCore/Sources/UIComponents/ARContainer.swift`, `ARContainerViewControllerDelegate.swift`
- Modify: `UMCAR/Sources/Presentation/AR/Views/ARView.swift`, `ARViewModel.swift`
- Modify: `UMCAR/Sources/Presentation/Overlay/Views/CheckScanOverlay.swift`
- Modify: `ARCoreDemoApp/ARCoreDemoApp/Sources/ContentView.swift`

**Interfaces:**
- Produces: `public enum ExhibitPhase { case initialized, scanning, browsing }`
  — Task 10이 첫 카드 인식 시 `.browsing`으로 전이시킨다

- [ ] **Step 1: ExhibitPhase를 만들고 GamePhase를 지운다**

`UMCAR/ARCore/Sources/Data/ExhibitPhase.swift`:

```swift
//
//  ExhibitPhase.swift
//  ARCore
//

import Foundation

/// 전시물의 진행 단계.
///
/// `scanning → browsing`은 단방향이다. 9장 중 몇 장을 찾았는지는 phase가 아니라
/// 별도 카운트로 노출한다 — 3장만 인식된 상태에서도 나머지를 계속 찾을 수 있어야
/// 하기 때문이다. 되돌아가는 전이가 없어서 예전 handleRemovedAnchors의 phase 가드
/// 버그가 구조적으로 재발하지 않는다 (DESIGN.md §3).
public enum ExhibitPhase {
    /// AR이 초기화만 되고 세션이 시작되지 않은 단계
    case initialized

    /// 세션이 돌고 있고 아직 카드를 하나도 못 찾은 단계
    case scanning

    /// 카드를 한 장 이상 찾아 열람 가능한 단계
    case browsing
}
```

```bash
git rm UMCAR/ARCore/Sources/Data/GamePhase.swift
```

- [ ] **Step 2: 포탈·배치·평면 파일을 지운다**

```bash
git rm UMCAR/ARCore/Sources/UIComponents/ARContainerViewController+Portal.swift
git rm UMCAR/ARCore/Sources/Features/AR/CentralPortalVisualizer.swift
git rm UMCAR/ARCore/Sources/UIComponents/ARContainerViewController+CardPlacement.swift
git rm UMCAR/ARCore/Sources/UIComponents/ARContainerViewController+PlaneDetection.swift
git rm UMCAR/ARCore/Sources/Features/AR/PlaneVisualizer.swift
git rm UMCAR/ARCore/Sources/Features/AR/ARFeatureProvider.swift
git rm -r UMCAR/ARCore/Packages/KonglishARProject
git rm UMCAR/UMCAR/Sources/Presentation/Overlay/Views/FinishedOverlay.swift
```

`ARCore/Project.swift`에서 `packages:` 줄과 `dependencies: [.package(product: "KonglishARProject")]`를
제거해 `dependencies: []`로 바꾼다.

> `ARFeatureProvider`는 구현체가 둘뿐인 데다 `associatedtype` 때문에 존재 타입으로 담기지도
> 않는다. 남은 구현체(`CardDetector`, `CardPositioner`)는 Task 11–12에서 프로토콜 없이 쓴다.

- [ ] **Step 3: 참조를 걷어낸다**

`GameSettings.swift`: `minimumSizeOfPlane` 프로퍼티와 `init` 파라미터 제거.

`ARContainerViewController.swift`: `planeVisualizer`, `portalVisualizer`,
`detectedPlaneEntities`, `savedPlaneTransforms` 제거. `gamePhase` 타입을
`GamePhase` → `ExhibitPhase`로 바꾼다.

`ARContainerViewControllerDelegate.swift`: `arContainerDidFindPlaneAnchor`,
`arContainerDidLosePlaneAnchor` 제거.

`ARContainer.swift`: `currentDetectedPlanes`, `triggerCreatePortal`, `triggerPlaceCards`
바인딩과 `updateUIViewController`의 해당 블록, `Coordinator`의 평면 콜백 2개 제거.
`gamePhage` 오타 프로퍼티를 `exhibitPhase`로 정리한다.

`ARViewModel.swift`: `currentDetectedPlanes`, `triggerOpenPortal`, `triggerPlaceCards`,
`placeCardsButtonTapped()` 제거. `gamePhase: GamePhase` → `exhibitPhase: ExhibitPhase`.

`ARView.swift`: `allPlanesDetected`, `minimumSizeOfPlane` 제거. 오버레이 `switch`를
`.initialized` / `.scanning` / `.browsing` 3분기로 줄인다 (이 시점에는
`CheckScanOverlay`와 `PlayingGameOverlay`를 그대로 쓰고, Task 13에서 교체한다).

`CheckScanOverlay.swift`: 포탈 생성/카드 배치 버튼 제거.

`ARCoreDemoApp/ContentView.swift`: 평면 수 표시, 포탈·배치 버튼 제거.

- [ ] **Step 4: 프로젝트 재생성 후 두 앱 빌드 확인**

```bash
cd UMCAR && mise exec tuist@4.155.0 -- tuist install && mise exec tuist@4.155.0 -- tuist generate --no-open
xcodebuild -workspace UMCAR.xcworkspace -scheme UMCAR -destination 'generic/platform=iOS' \
  build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|^\*\*" | sort -u
cd ../ARCoreDemoApp && mise exec tuist@4.155.0 -- tuist generate --no-open
xcodebuild -workspace ARCoreDemoApp.xcworkspace -scheme ARCoreDemoApp \
  -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|^\*\*" | sort -u
```

- [ ] **Step 5: 커밋**

```bash
git add -A
git commit -m "[Refactor] - 포탈·카드 배치·평면 감지 제거, GamePhase를 ExhibitPhase 3단계로

실물 카드가 이미 책상에 있으므로 배치할 것이 없고, 이미지 인식은 평면을 쓰지
않는다 (DESIGN.md §2, §3).

변경 사항:
- ARCore: +Portal, CentralPortalVisualizer, +CardPlacement, +PlaneDetection,
  PlaneVisualizer, ARFeatureProvider 삭제
- Packages/KonglishARProject(usdz 카드 씬) 삭제 및 ARCore/Project.swift 의존 제거
- GamePhase 9단계 → ExhibitPhase 3단계(initialized/scanning/browsing).
  paused는 어디서도 설정되지 않던 유령 케이스라 함께 제거
- GameSettings.minimumSizeOfPlane 제거
- 앱: FinishedOverlay 삭제, CheckScanOverlay에서 포탈·배치 버튼 제거

같이 정리된 문제: placeCards()가 public인데 호출부가 없던 죽은 코드,
handleRemovedAnchors의 .scanning 가드 버그가 코드째 사라졌다 (DESIGN.md §13).

영향 범위: ARCore 패키지 의존 변경으로 tuist install+generate 필요.
UMCAR·ARCoreDemoApp 양쪽 빌드 확인 완료."
```

---

## Task 8: SwiftData 제거

**Files:**
- Delete: `UMCAR/Sources/Model/DataBootstrapper.swift` (205줄)
- Delete: `UMCAR/Sources/Model/Domain/CardModel.swift` `CategoryModel.swift`
  `LevelModel.swift` `GameSessionModel.swift` `UsedCardModel.swift` `GameModelMapper.swift`
- Delete: `UMCAR/Sources/Common/Enum/Level/LevelType.swift` (83줄)
- Delete: `UMCAR/Resources/DataSets/*.json` (3개)
- Modify: `UMCAR/Sources/UMCARApp.swift`
- Modify: `UMCAR/Sources/Presentation/AR/Views/ARView.swift`

- [ ] **Step 1: SwiftData 계층을 지운다**

```bash
git rm UMCAR/UMCAR/Sources/Model/DataBootstrapper.swift
git rm UMCAR/UMCAR/Sources/Model/Domain/CardModel.swift
git rm UMCAR/UMCAR/Sources/Model/Domain/CategoryModel.swift
git rm UMCAR/UMCAR/Sources/Model/Domain/LevelModel.swift
git rm UMCAR/UMCAR/Sources/Model/Domain/GameSessionModel.swift
git rm UMCAR/UMCAR/Sources/Model/Domain/UsedCardModel.swift
git rm UMCAR/UMCAR/Sources/Model/Domain/GameModelMapper.swift
git rm UMCAR/UMCAR/Sources/Common/Enum/Level/LevelType.swift
git rm UMCAR/UMCAR/Resources/DataSets/categories-20250817.json
git rm UMCAR/UMCAR/Resources/DataSets/cards-20250817.json
git rm UMCAR/UMCAR/Resources/DataSets/levels-20250817.json
```

- [ ] **Step 2: 앱 진입점을 단순화한다**

`UMCAR/Sources/UMCARApp.swift` 전체를 다음으로 바꾼다:

```swift
import SwiftUI
import Dependency

@main
struct UMCARApp: App {
    @StateObject var container = DIContainer()

    var body: some Scene {
        WindowGroup {
            ARView()
                .id(container.gameSessionID)
                .environmentObject(container)
        }
    }
}
```

`ModelContainer`, `needBootstrapped()`, `setBootstrapSuccess()`, `hasBootstrapped`
플래그가 모두 사라진다.

- [ ] **Step 3: ARView에서 SwiftData 의존을 걷어낸다**

`ARView.swift`에서 제거:
- `import SwiftData`
- `@Environment(\.modelContext)`, `let levelModelID: UUID`, `@Query` 3개
- `selectedLevel`, `selectedGameSession` computed property
- `gameCards` computed property → `TechCard.all` 사용으로 대체

```swift
struct ARView: View {
    @EnvironmentObject var container: DIContainer
    @State var arViewModel: ARViewModel = .init()

    /// 앞면 이미지 타이틀 폰트
    let titleFont: UIFont = UMCARFontFamily.NPSFont.extraBold.font(size: 64)
    /// 앞면 이미지 서브타이틀 폰트
    let subtitleFont: UIFont = UMCARFontFamily.NPSFont.extraBold.font(size: 32)
    ...
}
```

> `ARContainer` 호출부는 아직 `GameSettings`를 받는다. Task 9에서 `ExhibitSettings`로
> 바꾼다. 이 태스크에서는 `GameSettings(gameCards:fontSetting:)`에
> `TechCard.all`을 `GameCard`로 변환해 넘기는 대신, **`GameSettings`의 `gameCards`
> 타입을 `[TechCard]`로 바꾸는 것이 더 짧다.** 그렇게 한다.

`ARCore/Sources/Data/GameCard.swift`를 삭제하고 `GameSettings.gameCards: [TechCard]`로
바꾼다. `CardComponent`, `CardContentImageProvider`, `CardContentImageWriter`,
`DynamicCardContentSystem`의 `GameCard` 참조를 `TechCard`로 치환한다.

- [ ] **Step 4: 빌드·테스트 확인**

```bash
cd UMCAR && mise exec tuist@4.155.0 -- tuist generate --no-open
xcodebuild -workspace UMCAR.xcworkspace -scheme UMCAR -destination 'generic/platform=iOS' \
  build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|^\*\*" | sort -u
xcodebuild test -workspace UMCAR.xcworkspace -scheme ARCore \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' 2>&1 | grep -E "Executed|error:"
```

기대: `** BUILD SUCCEEDED **`, `Executed 12 tests, with 0 failures`

- [ ] **Step 5: 커밋**

```bash
git add -A
git commit -m "[Refactor] - SwiftData 전량 제거, 카드 데이터를 TechCard로 통일

9장은 고정된 읽기 전용 콘텐츠고 저장할 사용자 상태가 없다 (DESIGN.md §6).

변경 사항:
- SwiftData 모델 5개, DataBootstrapper(205줄), GameModelMapper, LevelType 삭제
- Resources/DataSets/*.json 3개 삭제
- UMCARApp: ModelContainer와 hasBootstrapped 플래그 로직 제거
- ARView: @Query·modelContext 제거, levelModelID 파라미터 제거
- GameCard → TechCard로 통일 (GameSettings.gameCards 타입 변경)

같이 해소된 문제: GameModelMapper.swift:19가 imageName으로 카드 앞면 UIImage를
만들어 레퍼런스 이미지 이름 재사용과 충돌하던 문제가 매퍼째 사라졌다.

영향 범위: 앱 데이터 계층 전체. 기존 설치본의 SwiftData 저장소는 더 이상 읽지
않는다. 빌드·테스트 확인 완료."
```

---

# 페이즈 C — 인식 파이프라인

여기서부터 새 기능이 붙는다. **AR 동작 검증은 실기기 전용**이라, 각 태스크는 빌드
초록까지만 자동 검증하고 실기기 확인은 Task 14에 모은다.

## Task 9: ExhibitSettings와 세션 설정 전환

**Files:**
- Create: `ARCore/Sources/Data/ExhibitSettings.swift`
- Delete: `ARCore/Sources/Data/GameSettings.swift`
- Modify: `ARCore/Sources/UIComponents/ARContainerViewController+ARSetup.swift:54`
- Modify: `ARCore/Sources/UIComponents/ARContainerViewController.swift`
- Modify: `UMCAR/Sources/Presentation/AR/Views/ARView.swift`
- Modify: `UMCAR` 에셋에 `TechCards.arresourcegroup` 추가

**Interfaces:**
- Produces:
  - `public struct ExhibitSettings { let cards: [TechCard]; let referenceImages: Set<ARReferenceImage>; let fontSetting: ARCoreFontSetting }`
  - `ARContainerViewController(exhibitSettings:)`

- [ ] **Step 1: 본 앱 에셋에 AR 리소스 그룹을 만든다**

```bash
cd Tools
XCASSETS=../UMCAR/UMCAR/Resources/Assets/Assets.xcassets python3 make_ar_resource_group.py
./verify_ar_resource_group.sh ../UMCAR/UMCAR/Resources/Assets/Assets.xcassets 9
```

기대: `PASS: 9장 모두 물리 크기 0.09,0.13 m 로 컴파일됨`

- [ ] **Step 2: ExhibitSettings를 만든다**

`UMCAR/ARCore/Sources/Data/ExhibitSettings.swift`:

```swift
//
//  ExhibitSettings.swift
//  ARCore
//

import ARKit

/// 앱이 ARCore에 주입하는 설정.
///
/// ARCore는 콘텐츠를 모른다. 레퍼런스 이미지도 앱이 에셋에서 로드해 넘긴다 —
/// ARCore가 앱 번들을 직접 뒤지면 모듈 의존이 역전된다 (DESIGN.md §4).
public struct ExhibitSettings {
    /// 부스에 배치하는 카드들
    public let cards: [TechCard]

    /// 카드 뒷면 레퍼런스 이미지. 앱이 AR Resource Group에서 로드한다
    public let referenceImages: Set<ARReferenceImage>

    public let fontSetting: ARCoreFontSetting

    public init(cards: [TechCard],
                referenceImages: Set<ARReferenceImage>,
                fontSetting: ARCoreFontSetting) {
        self.cards = cards
        self.referenceImages = referenceImages
        ARCoreFontSystem.shared.configure(with: fontSetting)
        self.fontSetting = fontSetting
    }

    /// 이미지 이름으로 카드를 찾는다. ARImageAnchor 처리에서 쓴다.
    public func card(forReferenceImageNamed name: String) -> TechCard? {
        cards.first { $0.id == name }
    }
}
```

`GameSettings.swift`를 지우고 `ARContainerViewController`의 `gameSettings` 프로퍼티와
`init`을 `exhibitSettings`로 바꾼다.

- [ ] **Step 3: 세션 설정을 이미지 인식으로 바꾼다**

`+ARSetup.swift`의 `resetSession()`에서 `configuration.planeDetection = [.vertical]`(54행)을
다음으로 교체한다:

```swift
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = exhibitSettings.referenceImages
        // 0 = 추적 안 함. 추적을 켜면 동시 4장 상한에 걸리는데, 카드는 책상에
        // 고정이라 추적이 필요 없다. 이때도 관측된 이미지마다 앵커가 붙는다.
        configuration.maximumNumberOfTrackedImages = 0
        configuration.planeDetection = []
```

같은 파일에서 `arView.automaticallyConfigureSession = false`를 세션 실행 전에 설정한다.
빠뜨리면 ARView가 세션을 다시 구성하면서 `detectionImages`가 덮인다.

- [ ] **Step 4: 앱에서 레퍼런스 이미지를 로드해 주입한다**

`ARView.swift`:

```swift
    /// AR Resource Group에서 카드 뒷면 레퍼런스 이미지를 읽는다.
    /// 없으면 인식이 통째로 죽으므로 조용히 넘기지 않고 화면에 드러낸다.
    private var referenceImages: Set<ARReferenceImage> {
        ARReferenceImage.referenceImages(inGroupNamed: "TechCards", bundle: nil) ?? []
    }
```

`ARContainer(exhibitSettings: .init(cards: TechCard.all, referenceImages: referenceImages, fontSetting: ...))`로
호출부를 바꾼다.

- [ ] **Step 5: 빌드 확인 후 커밋**

```bash
cd UMCAR && mise exec tuist@4.155.0 -- tuist generate --no-open
xcodebuild -workspace UMCAR.xcworkspace -scheme UMCAR -destination 'generic/platform=iOS' \
  build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|^\*\*" | sort -u

git add -A
git commit -m "[Feat] - 세션 설정을 평면 감지에서 이미지 인식으로 전환

변경 사항:
- ARCore/Sources/Data/ExhibitSettings.swift 신규 — 카드 + 레퍼런스 이미지 + 폰트.
  GameSettings 대체
- +ARSetup.swift: planeDetection=[.vertical] → detectionImages + 
  maximumNumberOfTrackedImages=0, planeDetection=[]
- arView.automaticallyConfigureSession=false 추가 — 빠뜨리면 ARView가 세션을
  다시 구성하면서 detectionImages 설정이 덮인다
- UMCAR 에셋에 TechCards.arresourcegroup 추가 (9장, 0.09x0.13m)

왜 추적을 끄는가: 상한 4장은 추적 대상 수의 상한이다. 카드는 책상 고정이라
추적이 필요 없고, 끄면 9장 전부 앵커가 붙는다 (DESIGN.md §5).

영향 범위: 이 시점부터 앱은 평면을 인식하지 않는다. 앵커 처리는 Task 10.
빌드 확인 완료. verify_ar_resource_group.sh PASS."
```

---

## Task 10: 앵커 감지 → 씬 부착

**Files:**
- Create: `ARCore/Sources/Components/TechCardComponent.swift`
- Create: `ARCore/Sources/UIComponents/ARContainerViewController+ImageDetection.swift`
- Create: `ARCore/Sources/Features/AR/CardPanelBuilder.swift`
- Delete: `ARCore/Sources/Features/AR/CardPositioner.swift` (148줄)
- Modify: `ARCore/Sources/UIComponents/ARContainerViewControllerDelegate.swift`
- Modify: `ARCore/Sources/UIComponents/ARContainer.swift`

**Interfaces:**
- Produces:
  - `public struct TechCardComponent: Component { public let cardID: String }`
  - `func session(_:didAdd:)` — `ARImageAnchor` → 콜라이더 + 패널 부착
  - `CardPanelBuilder.build(card:physicalSize:) -> (hit: ModelEntity, panel: ModelEntity)`
  - 델리게이트 `func didDetectCard(_ arContainer: ARContainerViewController, cardID: String)`

- [ ] **Step 1: 컴포넌트를 만든다**

```swift
//
//  TechCardComponent.swift
//  ARCore
//

import RealityKit

/// 엔티티가 어느 카드인지 표시한다. 탭 히트 판정에서 조상을 거슬러 찾는다.
public struct TechCardComponent: Component {
    public let cardID: String

    public init(cardID: String) {
        self.cardID = cardID
    }
}
```

`ARContainerViewController`의 `viewDidLoad`에서 `TechCardComponent.registerComponent()`를 부른다.

- [ ] **Step 2: 패널 빌더를 만든다**

`ARCore/Sources/Features/AR/CardPanelBuilder.swift`:

```swift
//
//  CardPanelBuilder.swift
//  ARCore
//

import RealityKit
import UIKit

/// 카드 앵커에 붙일 엔티티를 만든다.
///
/// ARImageAnchor의 로컬 공간은 이미지가 x-z 평면에 눕고 +Y가 법선이다
/// (Apple 샘플: "ARImageAnchor assumes the image is horizontal in its local space").
/// RealityKit의 generatePlane(width:depth:)도 x-z 평면이라 회전 보정이 필요 없고,
/// 패널을 띄울 때는 +Y로 민다.
enum CardPanelBuilder {
    /// 패널이 카드 위로 뜨는 높이 (미터)
    static let panelLift: Float = 0.05

    static func build(cardID: String, physicalSize: CGSize) -> (hit: ModelEntity, panel: ModelEntity) {
        let width = Float(physicalSize.width)
        let depth = Float(physicalSize.height)

        // 히트 판정용 판. 렌더는 하지 않고 탭만 받는다.
        var invisible = UnlitMaterial(color: .clear)
        invisible.blending = .transparent(opacity: 0)
        let hit = ModelEntity(
            mesh: .generatePlane(width: width, depth: depth),
            materials: [invisible]
        )
        hit.components.set(TechCardComponent(cardID: cardID))
        hit.generateCollisionShapes(recursive: false)

        // 패널. 텍스처는 Task 12에서 굽는다.
        var placeholder = UnlitMaterial(color: .white)
        placeholder.blending = .transparent(opacity: 0.92)
        let panel = ModelEntity(
            mesh: .generatePlane(width: width, depth: depth),
            materials: [placeholder]
        )
        panel.position = [0, panelLift, 0]      // +Y = 카드 법선
        panel.isEnabled = false                  // 탭 전까지 숨김

        hit.addChild(panel)
        return (hit, panel)
    }
}
```

- [ ] **Step 3: 앵커 처리를 만든다**

`ARCore/Sources/UIComponents/ARContainerViewController+ImageDetection.swift`:

```swift
//
//  ARContainerViewController+ImageDetection.swift
//  ARCore
//

import ARKit
import RealityKit

extension ARContainerViewController {
    /// ARKit이 레퍼런스 이미지를 찾았을 때 호출된다.
    ///
    /// Apple 문서: "ARKit adds an image anchor to a session exactly once for each
    /// reference image." 그래도 이름이 카드와 안 맞는 경우는 로그만 남기고 넘어간다 —
    /// 에셋 이름과 TechCard.id가 어긋나면 여기서 조용히 실패하기 때문이다.
    func handleAddedImageAnchors(_ anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let imageAnchor = anchor as? ARImageAnchor else { continue }

            guard let name = imageAnchor.referenceImage.name else {
                logger.error("레퍼런스 이미지에 이름이 없다")
                continue
            }
            guard let card = exhibitSettings.card(forReferenceImageNamed: name) else {
                logger.error("등록되지 않은 카드다: \(name)")
                continue
            }
            guard cardEntities[card.id] == nil else { continue }

            let (hit, panel) = CardPanelBuilder.build(
                cardID: card.id,
                physicalSize: imageAnchor.referenceImage.physicalSize
            )

            let anchorEntity = AnchorEntity(anchor: imageAnchor)
            anchorEntity.addChild(hit)
            arView.scene.addAnchor(anchorEntity)

            cardEntities[card.id] = hit
            panelEntities[card.id] = panel

            if exhibitPhase == .scanning {
                exhibitPhase = .browsing
            }
            delegate?.didDetectCard(self, cardID: card.id)
            logger.info("카드 인식: \(card.id)")
        }
    }
}
```

`ARContainerViewController`에 저장소를 추가한다:

```swift
    /// 카드 id → 히트 판 엔티티
    var cardEntities: [String: ModelEntity] = [:]
    /// 카드 id → 패널 엔티티
    var panelEntities: [String: ModelEntity] = [:]
    /// 인식된 카드 수. SwiftUI가 n/9로 표시한다
    public var detectedCardCount: Int { cardEntities.count }
```

`ARSessionDelegate`의 `session(_:didAdd:)`에서 `handleAddedImageAnchors(anchors)`를 부른다.

- [ ] **Step 4: 델리게이트와 바인딩을 정리한다**

`ARContainerViewControllerDelegate`에 추가:

```swift
    /// 새 카드를 인식했을 때 호출된다.
    /// 인식된 총 개수는 `detectedCardCount`로 참조한다
    func didDetectCard(_ arContainer: ARContainerViewController, cardID: String)
```

`ARContainer`에 `@Binding var detectedCardCount: Int`를 추가하고 Coordinator에서 갱신한다.

```bash
git rm UMCAR/ARCore/Sources/Features/AR/CardPositioner.swift
```

- [ ] **Step 5: 빌드 확인 후 커밋**

```bash
cd UMCAR && mise exec tuist@4.155.0 -- tuist generate --no-open
xcodebuild -workspace UMCAR.xcworkspace -scheme UMCAR -destination 'generic/platform=iOS' \
  build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|^\*\*" | sort -u

git add -A
git commit -m "[Feat] - ARImageAnchor 감지 → 콜라이더·패널 부착

변경 사항:
- TechCardComponent — 엔티티에 카드 id를 붙인다
- +ImageDetection.swift — 앵커 → 카드 조회 → 씬 부착, 첫 인식 시 browsing 전이
- CardPanelBuilder — 히트 판(투명) + 패널 quad 생성. CardPositioner(148줄) 대체
- 델리게이트에 didDetectCard 추가, detectedCardCount 바인딩 추가

좌표계: ARImageAnchor 로컬은 이미지가 x-z 평면에 눕고 +Y가 법선이다. RealityKit의
generatePlane(width:depth:)도 x-z라 회전 보정 없이 쓰고 패널은 +Y로 5cm 띄운다
(DESIGN.md §5).

이름 불일치 방어: 에셋 이름과 TechCard.id가 어긋나면 인식은 되는데 조회가 실패한다.
조용히 넘기지 않고 에러 로그를 남긴다.

영향 범위: 빌드 확인 완료. 실제 앵커 동작은 실기기 검증(Task 14)에서 확인한다."
```

---

## Task 11: 탭 → 패널 토글

**Files:**
- Create: `ARCore/Sources/UIComponents/ARContainerViewController+Tap.swift`
- Delete: `ARCore/Sources/Features/AR/CardDetector.swift` (66줄)
- Modify: `ARCore/Sources/UIComponents/ARContainerViewController.swift`
- Modify: `ARCore/Sources/UIComponents/ARContainer.swift`

**Interfaces:**
- Consumes: `CardSelection` (Task 2), `TechCardComponent`·`panelEntities` (Task 10)
- Produces: 델리게이트 `func didChangeSelection(_ arContainer: ARContainerViewController, cardID: String?)`

- [ ] **Step 1: 탭 처리를 만든다**

`ARCore/Sources/UIComponents/ARContainerViewController+Tap.swift`:

```swift
//
//  ARContainerViewController+Tap.swift
//  ARCore
//

import RealityKit
import UIKit

extension ARContainerViewController {
    /// arView에 탭 제스처를 붙인다. viewDidLoad에서 부른다.
    ///
    /// SwiftUI로 탭 좌표를 왕복시키지 않는다 — 예전 구조는 trigger* Bool을 토글해
    /// 명령을 밀어넣었는데, 좌표를 넘기는 데 그 왕복이 필요하지 않다.
    func setupTapGesture() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(recognizer)
    }

    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: arView)
        let tappedCardID = cardID(at: point)

        switch selection.tap(tappedCardID) {
        case let .opened(id):
            panelEntities[id]?.isEnabled = true
        case let .closed(id):
            panelEntities[id]?.isEnabled = false
        case let .replaced(from, to):
            panelEntities[from]?.isEnabled = false
            panelEntities[to]?.isEnabled = true
        case .unchanged:
            return
        }

        delegate?.didChangeSelection(self, cardID: selection.selected)
    }

    /// 탭 지점에 카드가 있으면 그 id를, 없으면 nil을 준다.
    /// 히트한 엔티티가 자식일 수 있으므로 조상을 거슬러 찾는다.
    private func cardID(at point: CGPoint) -> String? {
        guard let hit = arView.entity(at: point) else { return nil }

        var entity: Entity? = hit
        while let current = entity {
            if let component = current.components[TechCardComponent.self] {
                return component.cardID
            }
            entity = current.parent
        }
        return nil
    }
}
```

`ARContainerViewController`에 `var selection = CardSelection()`을 추가하고
`viewDidLoad`에서 `setupTapGesture()`를 부른다.

```bash
git rm UMCAR/ARCore/Sources/Features/AR/CardDetector.swift
```

- [ ] **Step 2: 델리게이트와 바인딩을 잇는다**

`ARContainerViewControllerDelegate`에 추가:

```swift
    /// 선택된 카드가 바뀌었을 때 호출된다. nil이면 열린 패널이 없다
    func didChangeSelection(_ arContainer: ARContainerViewController, cardID: String?)
```

`ARContainer`에 `@Binding var selectedCardID: String?`를 추가하고 Coordinator에서 갱신한다.

- [ ] **Step 3: 빌드·테스트 확인 후 커밋**

```bash
cd UMCAR && mise exec tuist@4.155.0 -- tuist generate --no-open
xcodebuild -workspace UMCAR.xcworkspace -scheme UMCAR -destination 'generic/platform=iOS' \
  build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|^\*\*" | sort -u
xcodebuild test -workspace UMCAR.xcworkspace -scheme ARCore \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' 2>&1 | grep -E "Executed|error:"

git add -A
git commit -m "[Feat] - 카드 탭으로 패널 토글

변경 사항:
- +Tap.swift — UITapGestureRecognizer를 arView에 직접 붙이고 CardSelection으로
  열기/닫기/교체를 판정, 패널 엔티티 isEnabled 토글
- CardDetector(66줄) 삭제 — 화면 중앙 조준 방식이라 쓸모가 없다
- 델리게이트에 didChangeSelection 추가, selectedCardID 바인딩 추가

왜 SwiftUI를 거치지 않는가: 예전 구조는 trigger* Bool을 토글해 AR에 명령을
밀어넣었는데, 탭 좌표를 SwiftUI로 왕복시킬 이유가 없다 (DESIGN.md §5).

영향 범위: 빌드·테스트 확인 완료. 실제 히트 판정은 실기기 검증(Task 14)."
```

---

## Task 12: 패널 텍스처

**Files:**
- Modify: `ARCore/Sources/Features/DynamicTexture/CardContentImageWriter.swift:76`
- Modify: `ARCore/Sources/System/DynamicCardContentSystem.swift`
- Modify: `ARCore/Sources/Features/DynamicTexture/CardContentImageProvider.swift`

- [ ] **Step 1: imageFrom을 패널 레이아웃으로 바꾼다**

`CardContentImageWriter.imageFrom()`의 시그니처와 본문을 로고 + 기술명 + 태그 + 설명
문단 구성으로 바꾼다. 기존 구조(배경 → 이미지 draw → 제목 → 부제목 → PNG)를 유지하되
텍스트 rect를 문단에 맞게 넓히고 `NSAttributedString`으로 줄바꿈을 처리한다.

> **패널 레이아웃 수치는 미결이다** (DESIGN.md §12). 텍스처 해상도 ↔ 읽기 거리
> 트레이드오프라 실물을 보고 정한다. 이 태스크에서는 **읽을 수 있는 최소 구성**으로
> 두고, Task 14 실기기 검증 후 조정한다.

- [ ] **Step 2: 세션 시작 시 전량 웜업으로 바꾼다**

`DynamicCardContentSystem`이 매 프레임 쿼리로 굽는 구조를, 9장 고정이므로 세션 시작 시
`CardContentImageProvider`의 웜업 경로로 전량 굽도록 바꾼다. 부스에서 탭 후 텍스처가
늦게 뜨는 것보다 낫다.

- [ ] **Step 3: 패널 머티리얼에 텍스처를 물린다**

`CardPanelBuilder.build`의 placeholder 머티리얼을 구운 텍스처로 교체한다.
`UnlitMaterial`을 유지한다 — 부스 조명이 어두워도 텍스트가 어둡게 깔리지 않는다.

- [ ] **Step 4: 빌드 확인 후 커밋**

```bash
git add -A
git commit -m "[Feat] - 패널에 카드 설명 텍스처 적용

변경 사항:
- CardContentImageWriter.imageFrom() — 영단어+한글뜻 2줄 → 로고+기술명+태그+설명 문단
- DynamicCardContentSystem — 매 프레임 쿼리 → 세션 시작 시 전량 웜업.
  9장 고정이라 부스에서 탭 후 텍스처가 늦게 뜨는 것보다 낫다
- CardPanelBuilder — 패널 머티리얼에 구운 텍스처 연결. UnlitMaterial 유지
  (부스 조명이 어두워도 텍스트가 어둡게 깔리지 않는다)

미결: 패널 레이아웃 수치는 실물을 보고 정한다. 텍스처 해상도와 읽기 거리의
트레이드오프라 지금은 읽을 수 있는 최소 구성으로 뒀다 (DESIGN.md §12).

영향 범위: 빌드 확인 완료."
```

---

# 페이즈 D — 마감

## Task 13: 오버레이 3개로 재구성

**Files:**
- Create: `UMCAR/Sources/Presentation/Overlay/Views/ScanGuideOverlay.swift`
- Create: `UMCAR/Sources/Presentation/Overlay/Views/BrowsingOverlay.swift`
- Delete: `UMCAR/Sources/Presentation/Overlay/Views/CheckScanOverlay.swift`
- Delete: `UMCAR/Sources/Presentation/Overlay/Views/PlayingGameOverlay.swift`
- Modify: `UMCAR/Sources/Presentation/AR/Views/ARView.swift`
- Modify: `UMCAR/Sources/Presentation/AR/ViewModels/ARViewModel.swift`

`StartOverlay`는 그대로 둔다. `ScanGuideOverlay`는 "카드를 비춰주세요"와 n/9 카운트,
`BrowsingOverlay`는 종료 버튼과 인식 수만 둔다 (사용자 확인: 추가 안내 없음).

- [ ] **Step 1~4**: 오버레이 2개 작성 → `ARView` switch 3분기로 정리 → 빌드 확인 → 커밋

---

## Task 14: 실기기 검증

**자동 검증으로는 여기까지가 끝이다.** 아래는 사람이 실기기로 확인한다.

- [ ] 인쇄물(`Docs/Assets/ReferenceCards/print/*.png`)을 100% 배율·무광 용지로 출력, 재단
- [ ] 9장을 책상에 펼치고 iPad로 훑는다
- [ ] **9장이 각각 인식되는가** — 오버레이 카운트가 9/9까지 오르는가
- [ ] **오인식되는 쌍이 있는가**
- [ ] **패널이 카드 바로 위에 뜨는가** — 옆으로 서거나 파고들면 §5 좌표계 가정이 틀린 것
- [ ] **탭 히트 판정이 정확한가** — 인접 카드가 잘못 열리지 않는가
- [ ] **패널 글씨가 읽히는가** — 안 읽히면 Task 12의 레이아웃을 조정한다
- [ ] 부스 조명 조건에서 인식 거리 확인
- [ ] 발견한 문제를 `DESIGN.md` §12에 반영하고 커밋

---

## Task 15: 게임 잔재 리네이밍

기능 변경이 끝난 뒤 **순수 리네임 커밋 하나**로 분리한다. 로직 변경과 이름 변경이
섞이면 리뷰가 어려워진다.

- [ ] `ARContainerViewController` → `ExhibitViewController`
- [ ] `ARContainer` → `ExhibitContainer`
- [ ] `ARContainerViewControllerDelegate` → `ExhibitViewControllerDelegate`
- [ ] `ARViewModel.exhibitPhase` 등 잔여 `game*` 식별자 정리
- [ ] `DIContainer.gameSessionID` → `sessionID`
- [ ] 빌드·테스트 확인 후 커밋 (`[Refactor] - 게임 잔재 식별자 정리`)

---

## 자체 점검

- **설계 커버리지**: DESIGN.md §3(Task 7) §4(Task 9) §5(Task 9–12) §6(Task 3, 8)
  §7(Task 13) §8(완료) §9(Task 9) §10(Task 4–8) §11(Task 1–3) §13(Task 4–7에서 함께 해소).
  §12 미결 2건은 Task 12·14로 넘어간다.
- **타입 일관성**: `TechCard.id`(String)가 `CardSelection.tap`, `TechCardComponent.cardID`,
  `ExhibitSettings.card(forReferenceImageNamed:)`, 델리게이트 `cardID` 전부에서 String이다.
- **미해결 위험**: Task 8의 `GameCard → TechCard` 치환이 `CardComponent`,
  `DynamicTexture` 4개 파일에 걸쳐 있다. 여기서 컴파일 에러가 가장 많이 날 구간이다.
