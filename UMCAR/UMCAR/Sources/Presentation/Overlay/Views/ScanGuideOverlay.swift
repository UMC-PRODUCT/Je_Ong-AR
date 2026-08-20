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
        /// 인식은 즉시 되지 않는다. 가만히 기다리라고 말해주지 않으면
        /// 관람객이 반응 없는 화면을 보고 카메라를 계속 움직인다 —
        /// 그러면 더 안 잡힌다.
        static let guideText = "카드에 카메라를 맞추고 2초간 기다려주세요"
    }

    var body: some View {
        Color.clear
            // 이게 없으면 화면 전체를 덮은 Color가 탭을 삼켜 ARView가 못 받는다.
            // 카드 탭을 ARView가 직접 받는 구조라 배경은 히트 테스트에서 빠져야 한다.
            // 아래 overlay와 pauseButton은 이 뒤에 붙으므로 탭이 그대로 살아 있다.
            .allowsHitTesting(false)
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
