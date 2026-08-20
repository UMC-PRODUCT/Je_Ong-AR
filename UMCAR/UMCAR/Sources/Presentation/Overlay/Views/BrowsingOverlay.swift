//
//  BrowsingOverlay.swift
//  UMCAR
//

import SwiftUI
import Dependency

/// 카드를 한 장 이상 찾은 뒤의 오버레이.
///
/// 상단에 인식 수, 하단에 "탭하라"는 안내. 안내는 **열린 패널이 없을 때만** 띄운다 —
/// 부스는 관람객이 계속 바뀌므로 한 번 보여주고 마는 게 아니라, 아무것도 안 열린
/// 상태면 다음 사람에게 다시 보여야 한다. 패널이 열리면 숨겨서 화면을 비운다.
struct BrowsingOverlay: View {
    @Bindable var arViewModel: ARViewModel
    @EnvironmentObject var container: DIContainer

    private enum Constants {
        static let totalCards = 9
        static let cornerRadius: CGFloat = 20
        static let chipHorizontalPadding: CGFloat = 20
        static let chipVerticalPadding: CGFloat = 10
        static let guideHorizontalPadding: CGFloat = 32
        static let guideVerticalPadding: CGFloat = 16
        static let guideBottomPadding: CGFloat = 60
        static let dropShadowSize: CGFloat = 4
        static let guideStackSpacing: CGFloat = 6
        static let scanHintSpacing: CGFloat = 8
        static let guideText = "카드를 터치하면 설명이 나타납니다"
        /// 남은 카드를 찾을 때도 인식 대기는 똑같이 있다. 첫 장에서만
        /// 안내하고 마면 2장째부터 다시 헤맨다.
        static let scanHintText = "새 카드는 카메라를 맞추고 2초간 기다려주세요"
    }

    var body: some View {
        Color.clear
            // 이게 없으면 화면 전체를 덮은 Color가 탭을 삼켜 ARView가 못 받는다.
            .allowsHitTesting(false)
            .overlay(alignment: .top) {
                detectedCountChip
            }
            .overlay(alignment: .bottom) {
                if arViewModel.selectedCardID == nil {
                    tapGuide
                        .padding(.bottom, Constants.guideBottomPadding)
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: arViewModel.selectedCardID)
            .navigationBarBackButtonHidden(true)
            .safeAreaPadding(.trailing, UIConstants.naviLeadingPadding)
            .safeAreaPadding(.bottom, UIConstants.bottomPadding)
            .safeAreaPadding(.top, UIConstants.topPadding)
            .pauseButton()
    }

    private var detectedCountChip: some View {
        Text("\(arViewModel.detectedCardCount) / \(Constants.totalCards)")
            .appFont(.title3, weight: .semibold, color: .grey900)
            .monospacedDigit()
            .padding(.horizontal, Constants.chipHorizontalPadding)
            .padding(.vertical, Constants.chipVerticalPadding)
            .background(Material.ultraThin)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .grayShadow4()
    }

    /// 두 줄이다. 위는 지금 할 일(터치), 아래는 다음 카드를 찾는 법.
    /// 아래를 작고 흐리게 둬서 위가 먼저 읽히게 한다.
    private var tapGuide: some View {
        VStack(spacing: Constants.guideStackSpacing) {
            HStack(spacing: 10) {
                Image(systemName: "hand.tap.fill")
                Text(Constants.guideText)
            }
            .appFont(.title2, weight: .semibold, color: .grey900)

            HStack(spacing: Constants.scanHintSpacing) {
                Image(systemName: "camera.viewfinder")
                Text(Constants.scanHintText)
            }
            .appFont(.subheadline, weight: .medium, color: .grey600)
        }
        .padding(.horizontal, Constants.guideHorizontalPadding)
        .padding(.vertical, Constants.guideVerticalPadding)
        .background(Material.ultraThin)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .glassShadow(Constants.dropShadowSize)
    }
}

#Preview {
    BrowsingOverlay(arViewModel: .init())
        .environmentObject(DIContainer())
}
