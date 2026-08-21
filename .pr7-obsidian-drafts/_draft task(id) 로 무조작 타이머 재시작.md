---
created: 2026-08-21 10:56
type: tech-note
tags: [tech/ios, draft]
moc: "[[Tech MOC]]"
source_pr: "#7"
source_repo: "UMC-PRODUCT/Je_Ong-AR"
source_branch: "feature/intro-video → develop"
---

# task(id) 로 무조작 타이머 재시작

## 핵심 개념
> "마지막 활동 이후 N초" 타이머는 `Timer` 를 굴리고 `invalidate` 를 챙기는 대신, 활동 카운터를 `.task(id:)` 의 id 로 물려 SwiftUI 가 알아서 취소·재시작하게 만든다.

## 설명
무인 키오스크는 관람객이 말없이 떠난 상황을 감지해야 한다. 감지하지 못하면 다음 사람이 앞사람의 진행 상태를 그대로 이어받는다 — 부스 앱에서 이건 명백한 버그로 읽힌다.

전통적인 구현은 `Timer.scheduledTimer` 를 잡아두고 활동이 있을 때마다 `invalidate()` 후 다시 스케줄하는 것이다. 취소·재생성·뷰 소멸 시 정리를 전부 손으로 챙겨야 하고, 하나만 빠뜨려도 타이머가 살아남아 엉뚱한 시점에 발화한다.

`.task(id:)` 는 이 관리를 통째로 SwiftUI 에 넘긴다. **id 값이 바뀌면 실행 중이던 Task 를 취소하고 처음부터 다시 실행**하는 것이 이 API 의 계약이므로, 활동 신호마다 `Int` 카운터를 증가시키기만 하면 타이머가 리셋된다. 뷰가 사라질 때의 정리도 Task 취소로 자동 처리된다.

두 번째 설계 포인트는 **무엇을 활동 신호로 볼 것인가**다. 원시 탭(`onTapGesture`)이 직관적이지만, AR 화면에서 카드 탭은 UIKit 제스처가 처리하므로 SwiftUI 쪽으로 새지 않는다. 그래서 "탭"이 아니라 **탭의 결과로 바뀌는 상태**를 관찰한다 — 단계, 인식된 카드 수, 선택된 카드. 이 값들이 바뀌었다면 사람이 있는 것이고, 안 바뀌었다면 없는 것이다. 입력 이벤트보다 상태 변화를 신호로 쓰는 쪽이 제스처 처리 계층에 의존하지 않아 견고하다.

마지막으로 **타이머를 걸지 않을 상태**를 명시한다. 대기 화면은 아무도 없는 게 정상이므로 여기서 20초 후 재시작을 걸면 무의미한 뷰 재생성이 무한 반복된다. `guard` 로 빠져나가면 그 상태에서는 Task 가 즉시 끝난다.

## 코드 예시
```swift
/// 이만큼 아무 일도 없으면 관람객이 말없이 떠난 것으로 본다.
private static let inactivityTimeout: Duration = .seconds(20)

/// 무조작 타이머를 다시 재기 위한 토큰. 값이 바뀌면 `.task`가 취소되고
/// 처음부터 잰다. Timer 를 직접 굴리고 invalidate 를 챙기는 것보다 짧다.
@State private var activityToken = 0

// ...

// 관람객이 뭔가 하고 있다는 신호. 원시 탭을 잡지 않는 이유는 카드 탭이
// ARView 안의 UIKit 제스처로 처리돼서 SwiftUI 쪽에서 새는 경우가 있어서다.
// 이 네 가지가 바뀌었다면 사람이 있는 것이고, 안 바뀌었다면 없는 것이다.
.onChange(of: introStage)                 { activityToken += 1 }
.onChange(of: arViewModel.exhibitPhase)   { activityToken += 1 }
.onChange(of: arViewModel.detectedCardCount) { activityToken += 1 }
.onChange(of: arViewModel.selectedCardID) { activityToken += 1 }
.task(id: activityToken) {
    // 대기 화면은 아무도 없는 게 정상이다. 여기서는 영원히 기다린다.
    guard introStage != .idle else { return }

    try? await Task.sleep(for: Self.inactivityTimeout)
    guard !Task.isCancelled else { return }

    container.restartSession()
}
```

## 관련 노트
- MOC: [[Tech MOC]]
- 연관: [[모듈 public enum 대신 앱 레이어 State 로 단계 게이트]], [[키오스크 영상 재생의 fail-open 종료 경로]]

## 참조
- PR: #7 (https://github.com/UMC-PRODUCT/Je_Ong-AR/pull/7)
- 브랜치: feature/intro-video → develop
