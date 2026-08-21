---
created: 2026-08-21 10:56
type: tech-note
tags: [tech/ui, draft]
moc: "[[Tech MOC]]"
source_pr: "#7"
source_repo: "UMC-PRODUCT/Je_Ong-AR"
source_branch: "feature/intro-video → develop"
---

# 부스 키오스크 어트랙트 화면

## 핵심 개념
> 무인 부스 앱의 대기 화면은 "카메라 프리뷰를 가리고 · 화면 전체를 탭 타겟으로 잡고 · 깜빡임으로 시작 지점을 알리는" 세 가지를 동시에 만족해야 지나가는 사람이 시작점을 알아본다.

## 설명
AR 앱의 첫 화면을 그냥 카메라 프리뷰로 두면 지나가던 관람객에게 **"이미 누가 체험 중인 화면"** 으로 읽힌다. 부스 앱에서 이건 치명적이다 — 앱은 멀쩡히 대기 중인데 아무도 다가오지 않는다. 그래서 대기 상태에서는 프리뷰를 `Color.black` 으로 완전히 덮고, 로고와 프롬프트만 남긴다. 시각적으로 "꺼져 있지만 살아 있는" 상태를 만드는 것이 목적이다.

두 번째 결정은 **버튼을 두지 않은 것**이다. 부스에서 관람객은 화면을 정면으로 보지 않고 비스듬히 지나가며 곁눈질한다. 이때 화면 하단의 버튼 하나를 정확히 조준하는 것보다 "아무 데나 누르면 된다"가 인지 비용이 훨씬 낮다. 구현상 주의점은 `Color.black` 이 채운 영역이 기본적으로 탭을 받지 않는다는 것 — `.contentShape(Rectangle())` 를 걸어야 검정 영역까지 히트 테스트에 들어온다.

세 번째는 깜빡임(attract loop)이다. 정지된 화면은 "고장난 화면"과 구분되지 않는다. `repeatForever(autoreverses: true)` 로 프롬프트 텍스트 opacity 를 왕복시켜 살아 있음을 알린다. 다만 이건 접근성과 충돌하므로 `@Environment(\.accessibilityReduceMotion)` 이 켜져 있으면 **완전히 켜진 상태로 고정**한다 — 애니메이션만 끄고 dimmed 상태로 남기면 오히려 흐린 텍스트가 고정되어 더 나쁘다.

로고 크기는 "몇 걸음 떨어져서 읽히는가"가 기준이지 디자인 그리드가 기준이 아니다. 다만 원본 에셋 해상도가 상한을 만든다 — 여기서는 335px 원본이라 420pt 이상으로 키우면 캡션이 뭉갠다.

## 코드 예시
```swift
struct IdleOverlay: View {
    let onStart: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDimmed = false

    var body: some View {
        ZStack {
            Color.black   // 프리뷰가 비치면 "체험 중"으로 읽힌다

            VStack(spacing: 64) {
                Image(.umcLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 420)

                Text("Press the screen")
                    .appFont(.title1, weight: .semibold, color: .grey000)
                    .opacity(isDimmed ? 0.15 : 1)
            }
        }
        .ignoresSafeArea()
        // 버튼이 아니라 화면 전체가 시작 지점이다. 검정 영역까지 탭을 받아야 한다.
        .contentShape(Rectangle())
        .onTapGesture(perform: onStart)
        .onAppear {
            // 깜빡임을 끈 사용자에게는 완전히 켜진 상태로 고정한다.
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                isDimmed = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("화면을 눌러 체험을 시작하세요")
        .accessibilityAddTraits(.isButton)
    }
}
```

## 관련 노트
- MOC: [[Tech MOC]]
- 연관: [[모듈 public enum 대신 앱 레이어 State 로 단계 게이트]]

## 참조
- PR: #7 (https://github.com/UMC-PRODUCT/Je_Ong-AR/pull/7)
- 브랜치: feature/intro-video → develop
