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
        static let guideText = "카드를 터치하면 설명이 나타납니다"
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
            .font(.semibold20)
            .foregroundStyle(Color.black01)
            .monospacedDigit()
            .padding(.horizontal, Constants.chipHorizontalPadding)
            .padding(.vertical, Constants.chipVerticalPadding)
            .background(Material.ultraThin)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .grayShadow4()
    }

    private var tapGuide: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.tap.fill")
            Text(Constants.guideText)
        }
        .font(.semibold24)
        .foregroundStyle(Color.black01)
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
