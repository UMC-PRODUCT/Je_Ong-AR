---
created: 2026-08-21 10:56
type: tech-note
tags: [tech/ios, draft]
moc: "[[Tech MOC]]"
source_pr: "#7"
source_repo: "UMC-PRODUCT/Je_Ong-AR"
source_branch: "feature/intro-video → develop"
---

# AVPlayerLayer 로 컨트롤 없는 영상 재생

## 핵심 개념
> AVKit `VideoPlayer` 는 재생 컨트롤 UI 를 떼어낼 수 없으므로, 컨트롤이 한 프레임도 보이면 안 되는 화면에서는 `layerClass` 를 `AVPlayerLayer` 로 오버라이드한 `UIViewRepresentable` 을 쓴다.

## 설명
SwiftUI 의 `VideoPlayer` 는 편하지만 재생 컨트롤 오버레이가 함께 딸려 온다. `.disabled()` 나 `.allowsHitTesting(false)` 로 **상호작용**은 막을 수 있어도 컨트롤이 **그려지는 것** 자체는 못 막는다. 키오스크·인트로 영상처럼 "관람객이 재생바를 보면 안 되는" 화면에서는 이게 그대로 결함이다.

해결책은 UIKit 레이어를 직접 얹는 것이다. `UIView` 의 `layerClass` 를 `AVPlayerLayer.self` 로 오버라이드하면 그 뷰의 backing layer 자체가 `AVPlayerLayer` 가 된다. `addSublayer` 로 붙이는 방식과 달리 **레이아웃이 자동으로 따라오므로** `layoutSubviews` 에서 `frame` 을 수동 동기화할 필요가 없다 — 이게 이 패턴의 실질적 이득이다.

`videoGravity` 는 소스와 디바이스 종횡비 관계로 결정한다. 영상 16:9 를 아이패드 4:3 에 올리면 `.resizeAspect` 로 위아래 레터박스가 생기고, `.resizeAspectFill` 로 잘라내면 영상 상하단 자막·로고가 날아간다. 인트로 영상은 보통 화면 끝까지 정보가 차 있으므로 레터박스를 받아들이는 쪽이 맞다.

`layer as! AVPlayerLayer` 의 강제 캐스팅은 `layerClass` 가 타입을 보장하므로 안전하다 — 이건 옵셔널 바인딩으로 감쌀 필요가 없는 몇 안 되는 케이스다.

## 코드 예시
```swift
/// AVKit `VideoPlayer`는 재생 컨트롤 UI를 달고 온다. 부스 키오스크에서는 그
/// 컨트롤이 한 프레임이라도 보이면 안 되므로 레이어를 직접 얹는다.
private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.backgroundColor = .black
        // 영상은 16:9, 아이패드는 4:3이라 위아래 레터박스는 불가피하다.
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.playerLayer.player = player
    }

    final class PlayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        // layerClass가 보장한다.
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

// 사용부 — 스킵 불가 요구사항이라 히트 테스트 자체를 끈다.
ZStack {
    Color.black
    if let player { PlayerLayerView(player: player) }
}
.ignoresSafeArea()
.allowsHitTesting(false)
```

## 관련 노트
- MOC: [[Tech MOC]]
- 연관: [[키오스크 영상 재생의 fail-open 종료 경로]], [[무음 모드에서도 소리 내는 AVAudioSession playback]]

## 참조
- PR: #7 (https://github.com/UMC-PRODUCT/Je_Ong-AR/pull/7)
- 브랜치: feature/intro-video → develop
