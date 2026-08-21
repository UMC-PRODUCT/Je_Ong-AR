---
created: 2026-08-21 10:56
type: tech-note
tags: [tech/arch, draft]
moc: "[[Tech MOC]]"
source_pr: "#7"
source_repo: "UMC-PRODUCT/Je_Ong-AR"
source_branch: "feature/intro-video → develop"
---

# 모듈 public enum 대신 앱 레이어 State 로 단계 게이트

## 핵심 개념
> 새 단계를 붙일 때 하위 모듈의 public enum 에 케이스를 추가할지, 앱 레이어에 별도 `@State` 게이트를 둘지는 "그 모듈이 이 단계를 알아야 하는가"로 갈린다 — 몰라도 되면 앱 레이어에 둔다.

## 설명
전시 흐름에 인트로 영상 단계를 끼워 넣을 때 자연스러워 보이는 선택은 기존 `ExhibitPhase`(ARCore 모듈의 public enum)에 `.intro` 케이스를 추가하는 것이다. 하지만 인트로는 **ARCore 가 알 필요가 없는 앱 레이어 관심사**다. AR 세션 입장에서 인트로는 존재하지 않는 개념이고, 여기에 케이스를 추가하면:

- ARCore 를 쓰는 모든 소비자가 처리해야 할 케이스가 하나 늘어난다 (`switch` 전수 처리)
- public API 표면이 넓어져 모듈 재사용성이 떨어진다
- "AR 코어가 왜 인트로 영상을 아는가"라는 개념 누수가 생긴다

그래서 앱 레이어에 `private enum IntroStage { case idle, playing, done }` 를 두고 `@State` 로 관리한다. **중첩 switch** 가 되지만(`introStage` → `.done` 안에서 다시 `exhibitPhase`), 이 중첩이 곧 레이어 경계를 그대로 드러내므로 오히려 읽기 좋다.

`@State` 를 고른 데는 두 번째 효과가 있다. 세션 재시작이 `.id(container.sessionID)` 로 뷰를 **새로 만드는** 방식이라면, `@State` 는 자동으로 초기값 `.idle` 로 돌아간다. 상태 초기화 코드를 따로 쓸 필요가 없고, "재시작 시 리셋 빠뜨림" 버그가 구조적으로 불가능해진다. ViewModel 이나 전역 컨테이너에 뒀다면 리셋 로직을 손으로 챙겨야 했을 자리다.

`.initialized` 케이스가 `EmptyView()` 인 것도 같은 맥락이다. 인트로가 끝나고 스캔 트리거를 쏜 뒤 하위 모듈의 상태가 따라오기까지 한 프레임의 공백이 있는데, 이건 앱 레이어가 감당해야 할 비용이지 하위 모듈의 케이스를 바꿔서 없앨 문제가 아니다.

## 코드 예시
```swift
/// 인트로 영상 게이트. `ExhibitPhase`에 끼워 넣지 않는다 — 인트로는 ARCore가
/// 알 필요 없는 앱 레이어 관심사고, public enum을 건드릴 이유가 없다.
///
/// `@State`라서 `restartSession()`이 `.id(container.sessionID)`로 이 뷰를 새로
/// 만들 때 `.idle`로 돌아간다. 다음 관람객은 영상부터 다시 본다.
private enum IntroStage {
    case idle     // 아무도 없는 대기 상태
    case playing  // 영상 재생 중. 스킵 불가
    case done     // 이 뒤로는 기존 전시 흐름 그대로
}
@State private var introStage: IntroStage = .idle

// ...

.overlay {
    Group {
        switch introStage {
        case .idle:
            IdleOverlay { introStage = .playing }
        case .playing:
            IntroVideoView {
                introStage = .done
                // 확인 화면 없이 바로 스캔으로 넘긴다. 영상을 끝까지 본
                // 관람객에게 "시작하시겠습니까"를 한 번 더 묻는 건 군더더기다.
                arViewModel.startButtonTapped()
            }
        case .done:
            switch arViewModel.exhibitPhase {
            case .initialized:
                // 스캔 트리거가 ExhibitContainer 에 반영되기 전 한 프레임.
                EmptyView()
            case .scanning:
                ScanGuideOverlay(arViewModel: arViewModel)
            case .browsing:
                BrowsingOverlay(arViewModel: arViewModel)
            }
        }
    }
}
```

## 관련 노트
- MOC: [[Tech MOC]]
- 연관: [[부스 키오스크 어트랙트 화면]], [[task(id) 로 무조작 타이머 재시작]]

## 참조
- PR: #7 (https://github.com/UMC-PRODUCT/Je_Ong-AR/pull/7)
- 브랜치: feature/intro-video → develop
