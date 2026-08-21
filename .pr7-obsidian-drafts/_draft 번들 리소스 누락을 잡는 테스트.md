---
created: 2026-08-21 10:56
type: tech-note
tags: [tech/test, draft]
moc: "[[Tech MOC]]"
source_pr: "#7"
source_repo: "UMC-PRODUCT/Je_Ong-AR"
source_branch: "feature/intro-video → develop"
---

# 번들 리소스 누락을 잡는 테스트

## 핵심 개념
> fail-open 으로 조용히 건너뛰는 코드는 실패해도 런타임에 티가 안 나므로, 그 유일한 실패 모드(리소스가 번들에 없음)를 테스트로 못 박아야 한다.

## 설명
[[키오스크 영상 재생의 fail-open 종료 경로]] 처럼 실패 시 조용히 다음 단계로 넘기는 설계에는 대가가 따른다. **실패가 눈에 띄지 않는다**는 것이다. 인트로 영상이 번들에 없으면 앱은 아무 일 없다는 듯 스캔 화면으로 넘어가고, 아무도 이상하다고 느끼지 않는다. 시연 당일까지 모른다.

이 실패 모드가 실제로 발생하는 경로는 몇 가지다:

- Tuist `resources: ["Resources/**"]` glob 이 확장자나 하위 경로 때문에 mp4 를 빠뜨림
- 파일명 오타 또는 최종본 교체 시 상수와 파일명이 어긋남
- 리소스가 다른 타깃에 붙어서 `Bundle.main` 에 없음

전부 빌드는 성공한다. 컴파일러가 잡아줄 수 없는 영역이다. 그래서 **런타임 조회를 그대로 테스트로 옮긴다** — 프로덕션 코드가 쓰는 상수(`resourceName` / `resourceExtension`)를 테스트에서 재사용하는 것이 핵심이다. 문자열을 테스트에 다시 쓰면 파일명이 바뀔 때 테스트만 통과하는 상황이 생긴다.

실패 메시지에는 "무엇이 없다"가 아니라 **"없으면 무슨 일이 벌어지는가"** 를 쓴다. 이 테스트가 CI 에서 깨졌을 때 읽는 사람은 fail-open 설계를 모를 수 있다.

이 패턴은 영상에만 해당하지 않는다. 폰트, 사운드, `.reality` 파일, JSON 시드 데이터처럼 **번들에서 이름으로 찾는 모든 리소스**에 같은 3줄 테스트가 유효하다.

## 코드 예시
```swift
@testable import UMCAR

final class UMCARTests: XCTestCase {
    /// 인트로는 영상을 못 찾으면 조용히 건너뛴다 — 갇히는 것보다 낫지만, 그래서
    /// Tuist glob이 mp4를 빠뜨리거나 파일명이 틀려도 런타임에 티가 안 난다.
    /// 그 유일한 실패 모드를 여기서 잡는다.
    func test_인트로_영상이_앱_번들에_포함된다() {
        let url = Bundle.main.url(
            forResource: IntroVideoView.IntroVideoConstants.resourceName,
            withExtension: IntroVideoView.IntroVideoConstants.resourceExtension
        )

        XCTAssertNotNil(
            url,
            "\(IntroVideoView.IntroVideoConstants.resourceName).\(IntroVideoView.IntroVideoConstants.resourceExtension)이 번들에 없다 — 인트로 영상이 조용히 건너뛰어진다"
        )
    }
}
```

> 상수를 `internal`(기본 접근 수준) 로 열어 두어야 `@testable import` 로 재사용할 수 있다. `private` 로 감추면 테스트에서 문자열을 다시 쓰게 되고, 그 순간 이 테스트의 의미가 사라진다.

## 관련 노트
- MOC: [[Tech MOC]]
- 연관: [[키오스크 영상 재생의 fail-open 종료 경로]]

## 참조
- PR: #7 (https://github.com/UMC-PRODUCT/Je_Ong-AR/pull/7)
- 브랜치: feature/intro-video → develop
