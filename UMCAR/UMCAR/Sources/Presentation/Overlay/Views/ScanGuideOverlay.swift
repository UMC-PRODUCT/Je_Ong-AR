//
//  ScanGuideOverlay.swift
//  UMCAR
//

import SwiftUI
import Dependency

/// 카드를 아직 하나도 못 찾은 동안 보여주는 오버레이.
///
/// 예전 CheckScanOverlay를 대체한다. "스캔이 끝나고 다음 단계로 넘어가는" 조작이
/// 없어졌다 — 카드는 인식되는 대로 바로 열람 가능해지고, 첫 장이 잡히면
/// 페이즈가 browsing으로 넘어간다.
struct ScanGuideOverlay: View {
    @Bindable var arViewModel: ARViewModel
    @EnvironmentObject var container: DIContainer

    private enum Constants {
        static let totalCards = 9
        static let guideText = "책상 위 카드를 천천히 비춰주세요"
    }

    var body: some View {
        Color.clear
            .overlay(alignment: .top) {
                ChekScanCamera(
                    currentCount: $arViewModel.detectedCardCount,
                    maxCount: Constants.totalCards,
                    guideText: Constants.guideText
                )
            }
            .navigationBarBackButtonHidden(true)
            .safeAreaPadding(.trailing, UIConstants.naviLeadingPadding)
            .safeAreaPadding(.bottom, UIConstants.bottomPadding)
            .safeAreaPadding(.top, UIConstants.topPadding)
            .pauseButton()
    }
}

#Preview {
    ScanGuideOverlay(arViewModel: .init())
        .environmentObject(DIContainer())
}
