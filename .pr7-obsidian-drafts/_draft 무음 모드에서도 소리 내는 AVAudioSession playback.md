---
created: 2026-08-21 10:56
type: tech-note
tags: [tech/ios, draft]
moc: "[[Tech MOC]]"
source_pr: "#7"
source_repo: "UMC-PRODUCT/Je_Ong-AR"
source_branch: "feature/intro-video → develop"
---

# 무음 모드에서도 소리 내는 AVAudioSession playback

## 핵심 개념
> iOS 앱의 기본 오디오 세션 카테고리(`.soloAmbient`)는 무음 스위치를 따르므로, 소리가 콘텐츠의 일부인 재생에는 `.playback` 카테고리를 명시해야 한다.

## 설명
iOS 앱은 별도 설정이 없으면 `.soloAmbient` 카테고리로 동작한다. 이 카테고리는 **무음(silent) 스위치를 존중**한다 — 게임 효과음처럼 "없어도 되는 소리"에는 맞는 기본값이다. 반대로 영상·음악처럼 소리가 콘텐츠 본체인 경우에는 `.playback` 을 써야 무음 모드에서도 소리가 나간다.

이게 개발 중에 잘 안 드러나는 이유는 시뮬레이터에 무음 스위치가 없고, 개발자 기기는 보통 무음이 꺼져 있기 때문이다. 문제는 배치 현장에서 터진다 — 부스 아이패드가 무음 스위치가 켜진 채로 놓이는 사고는 실제로 흔하다. 코드로 못 박아두지 않으면 현장에서 소리 없는 인트로가 하루 종일 돌아간다.

`mode` 는 용도에 맞춰 준다. 영상 재생은 `.moviePlayback` 이 적절하다.

실패 처리 방향에 주의. 오디오 세션 설정 실패는 **재생을 중단할 이유가 아니다** — 소리가 없더라도 영상은 나가는 편이 낫다. `do-catch` 로 잡고 로그만 남기고 계속 진행한다. 세션 설정 실패에 `try!` 를 쓰면 소리 문제가 크래시로 승격된다.

## 코드 예시
```swift
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
player.play()
```

| 카테고리 | 무음 스위치 | 다른 앱 오디오 | 용도 |
|---|---|---|---|
| `.soloAmbient` (기본) | 따름 (소리 안 남) | 중단시킴 | 효과음 |
| `.ambient` | 따름 | 섞임 | 배경 효과음 |
| `.playback` | **무시 (소리 남)** | 중단시킴 | 영상 · 음악 |

## 관련 노트
- MOC: [[Tech MOC]]
- 연관: [[AVPlayerLayer 로 컨트롤 없는 영상 재생]]

## 참조
- PR: #7 (https://github.com/UMC-PRODUCT/Je_Ong-AR/pull/7)
- 브랜치: feature/intro-video → develop
