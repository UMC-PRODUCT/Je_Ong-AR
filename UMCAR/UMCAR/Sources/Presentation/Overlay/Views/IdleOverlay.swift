//
//  IdleOverlay.swift
//  UMCAR
//

import SwiftUI

/// 관람객을 기다리는 부스 대기 화면. 화면 아무 곳이나 누르면 인트로 영상이 나간다.
///
/// 카메라 프리뷰를 검정으로 덮는다. 프리뷰가 비치면 "이미 체험 중"으로 읽혀서
/// 지나가는 사람이 시작 지점을 못 알아본다.
struct IdleOverlay: View {
    let onStart: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Constants
    fileprivate enum IdleOverlayConstants {
        /// 몇 걸음 떨어져서도 읽혀야 하는 부스 어트랙트 화면이라 크게 잡는다.
        /// 원본 에셋이 335px뿐이라 여기서 더 키우면 캡션이 눈에 띄게 뭉갠다.
        static let logoWidth: CGFloat = 420
        static let spacing: CGFloat = 64
        static let prompt: String = "Press the screen"
        static let blinkDuration: Double = 0.9
        static let dimmedOpacity: Double = 0.15
        static let accessibilityLabel: String = "화면을 눌러 체험을 시작하세요"
    }

    @State private var isDimmed = false

    var body: some View {
        ZStack {
            Color.black

            VStack(spacing: IdleOverlayConstants.spacing) {
                Image(.umcLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: IdleOverlayConstants.logoWidth)

                Text(IdleOverlayConstants.prompt)
                    .appFont(.title1, weight: .semibold, color: .grey000)
                    .opacity(isDimmed ? IdleOverlayConstants.dimmedOpacity : 1)
            }
        }
        .ignoresSafeArea()
        // 버튼이 아니라 화면 전체가 시작 지점이다. 검정 영역까지 탭을 받아야 한다.
        .contentShape(Rectangle())
        .onTapGesture(perform: onStart)
        .onAppear {
            // 깜빡임을 끈 사용자에게는 완전히 켜진 상태로 고정한다.
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: IdleOverlayConstants.blinkDuration)
                .repeatForever(autoreverses: true)
            ) {
                isDimmed = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(IdleOverlayConstants.accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    IdleOverlay(onStart: {})
}
