//
//  IntroVideoView.swift
//  UMCAR
//

import SwiftUI
import AVFoundation

/// 부스 진입 인트로 영상. 재생이 끝나면 `onFinish`를 호출한다.
///
/// 스킵이 없다 — 관람객이 끝까지 보게 하는 게 요구사항이다. 대신 스킵이 없다는
/// 건 재생이 어떤 이유로든 진행되지 않으면 화면에 갇힌다는 뜻이므로, 파일 없음 ·
/// 재생 실패 · 종료 노티 유실을 전부 `onFinish`로 흘려보낸다. 부스에서 멈춰 선
/// 아이패드는 영상을 못 본 것보다 나쁘다.
struct IntroVideoView: View {
    let onFinish: () -> Void

    enum IntroVideoConstants {
        static let resourceName: String = "Finall"
        static let resourceExtension: String = "mp4"
        /// 영상 길이(8초) + 여유. 종료 노티가 끝내 오지 않는 경우의 최후 방어선이다.
        static let watchdog: Duration = .seconds(12)
    }

    @State private var player: AVPlayer?
    @State private var hasFinished = false

    var body: some View {
        ZStack {
            Color.black

            if let player {
                PlayerLayerView(player: player)
            }
        }
        .ignoresSafeArea()
        // 컨트롤도 제스처도 없다. 탭으로 건너뛸 수 없어야 한다.
        .allowsHitTesting(false)
        .onReceive(NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification)) { _ in
            finish()
        }
        .onReceive(NotificationCenter.default.publisher(for: AVPlayerItem.failedToPlayToEndTimeNotification)) { _ in
            print("⚠️ 인트로 영상 재생에 실패했다 — 건너뛴다")
            finish()
        }
        .task {
            startPlayback()

            try? await Task.sleep(for: IntroVideoConstants.watchdog)
            guard !Task.isCancelled else { return }
            print("⚠️ 인트로 영상이 \(IntroVideoConstants.watchdog) 안에 끝나지 않았다 — 건너뛴다")
            finish()
        }
    }

    private func startPlayback() {
        guard let url = Bundle.main.url(
            forResource: IntroVideoConstants.resourceName,
            withExtension: IntroVideoConstants.resourceExtension
        ) else {
            print("⚠️ 인트로 영상 \(IntroVideoConstants.resourceName).\(IntroVideoConstants.resourceExtension)을 번들에서 찾지 못했다 — 건너뛴다")
            finish()
            return
        }

        // 부스 아이패드가 무음 스위치가 켜진 채로 배치되는 사고는 실제로 흔하다.
        // .playback 카테고리라야 무음 모드에서도 소리가 나간다.
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback)
            try session.setActive(true)
        } catch {
            // 소리가 없더라도 영상은 나가는 편이 낫다.
            print("⚠️ 오디오 세션 설정 실패: \(error)")
        }

        let player = AVPlayer(url: url)
        player.actionAtItemEnd = .pause
        self.player = player
        player.play()
    }

    /// 종료 경로가 셋(정상 종료 · 재생 실패 · 워치독)이라 중복 호출을 막는다.
    private func finish() {
        guard !hasFinished else { return }
        hasFinished = true
        player?.pause()
        onFinish()
    }
}

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

#Preview {
    IntroVideoView(onFinish: {})
}
