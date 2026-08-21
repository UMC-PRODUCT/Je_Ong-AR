---
created: 2026-08-21 10:56
type: tech-note
tags: [tech/arch, draft]
moc: "[[Tech MOC]]"
source_pr: "#7"
source_repo: "UMC-PRODUCT/Je_Ong-AR"
source_branch: "feature/intro-video → develop"
---

# 키오스크 영상 재생의 fail-open 종료 경로

## 핵심 개념
> 스킵할 수 없는 화면은 "재생이 어떤 이유로든 진행되지 않으면 갇힌다"는 뜻이므로, 실패를 에러 화면이 아니라 **정상 종료와 같은 출구**로 흘려보내고(fail-open) 워치독으로 마지막 방어선을 둔다.

## 설명
"인트로를 끝까지 보게 한다"는 요구사항은 스킵 버튼 제거로 구현된다. 그런데 스킵을 없애는 순간, 재생이 시작되지 않거나 종료 노티가 유실되면 **관람객이 검은 화면 앞에 갇힌다**. 부스에서 멈춰 선 아이패드는 영상을 못 본 것보다 나쁘다 — 앞사람이 고장 화면을 보고 떠나면 그 뒤 줄이 통째로 사라진다.

그래서 이 화면의 실패 정책은 fail-closed(에러 표시 후 대기)가 아니라 **fail-open** 이다. 실패했으면 조용히 다음 단계로 넘긴다. 종료 경로는 셋이다:

1. **정상 종료** — `AVPlayerItem.didPlayToEndTimeNotification`
2. **재생 실패** — `AVPlayerItem.failedToPlayToEndTimeNotification`, 그리고 번들에서 파일을 못 찾은 경우
3. **워치독** — `영상 길이 + 여유` 만큼 기다렸는데 1·2 어느 것도 안 왔을 때

워치독은 1·2 를 신뢰할 수 없다는 전제에서 나온다. 노티는 옵저버 등록 타이밍·아이템 교체·백그라운드 전환 등으로 유실될 수 있고, 그 확률이 낮아도 부스는 하루에 수백 번 돌아가므로 결국 밟힌다. 시간은 콘텐츠 길이에 여유를 더해 잡는다(영상 8초 → 워치독 12초). 너무 짧으면 정상 재생을 잘라먹고, 너무 길면 갇힌 시간이 그대로 체감된다.

경로가 셋이므로 **중복 호출 방어**가 필수다. `hasFinished` 플래그 하나로 게이트를 잡는다. `@State` 로 두면 뷰가 사라질 때 함께 사라지므로 별도 정리가 필요 없다. 워치독은 `.task` 안의 `Task.sleep` 으로 두면 뷰 소멸 시 자동 취소되어 `Timer` 의 `invalidate` 챙기기를 안 해도 된다.

한 가지 더 — 실패 경로마다 `print` 로 흔적을 남긴다. fail-open 은 정의상 조용히 넘어가므로, 로그가 없으면 "영상이 원래 안 나오는 건가?"를 현장에서 판별할 방법이 없다.

## 코드 예시
```swift
struct IntroVideoView: View {
    let onFinish: () -> Void

    enum IntroVideoConstants {
        static let resourceName = "Finall"
        static let resourceExtension = "mp4"
        /// 영상 길이(8초) + 여유. 종료 노티가 끝내 오지 않는 경우의 최후 방어선이다.
        static let watchdog: Duration = .seconds(12)
    }

    @State private var player: AVPlayer?
    @State private var hasFinished = false

    var body: some View {
        content
            // 경로 1: 정상 종료
            .onReceive(NotificationCenter.default.publisher(
                for: AVPlayerItem.didPlayToEndTimeNotification)) { _ in finish() }
            // 경로 2: 재생 실패
            .onReceive(NotificationCenter.default.publisher(
                for: AVPlayerItem.failedToPlayToEndTimeNotification)) { _ in
                print("⚠️ 인트로 영상 재생에 실패했다 — 건너뛴다")
                finish()
            }
            .task {
                startPlayback()   // 파일 없음도 내부에서 finish() 로 흘린다

                // 경로 3: 워치독
                try? await Task.sleep(for: IntroVideoConstants.watchdog)
                guard !Task.isCancelled else { return }
                print("⚠️ 인트로 영상이 시간 안에 끝나지 않았다 — 건너뛴다")
                finish()
            }
    }

    /// 종료 경로가 셋(정상 종료 · 재생 실패 · 워치독)이라 중복 호출을 막는다.
    private func finish() {
        guard !hasFinished else { return }
        hasFinished = true
        player?.pause()
        onFinish()
    }
}
```

## 관련 노트
- MOC: [[Tech MOC]]
- 연관: [[AVPlayerLayer 로 컨트롤 없는 영상 재생]], [[번들 리소스 누락을 잡는 테스트]]

## 참조
- PR: #7 (https://github.com/UMC-PRODUCT/Je_Ong-AR/pull/7)
- 브랜치: feature/intro-video → develop
