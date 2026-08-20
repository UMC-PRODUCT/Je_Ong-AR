//
//  CheckScanOverlay.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/29/25.
//

import SwiftUI
import Dependency

/// 카드를 찾는 동안 보여주는 오버레이.
///
/// 포탈 생성 버튼이 사라졌다. 전시물에는 "스캔이 끝나고 다음 단계로 넘어가는" 조작이
/// 없다 — 카드는 인식되는 대로 바로 열람 가능해진다. Task 13에서 ScanGuideOverlay로
/// 다듬는다.
struct CheckScanOverlay: View {
    @Bindable var arViewModel: ARViewModel
    @EnvironmentObject var container: DIContainer

    var body: some View {
        Color.clear
            .overlay(alignment: .top, content: {
                ChekScanCamera(currentCount: $arViewModel.detectedCardCount)
            })
            .navigationBarBackButtonHidden(true)
            .safeAreaPadding(.trailing, UIConstants.naviLeadingPadding)
            .safeAreaPadding(.bottom, UIConstants.bottomPadding)
            .safeAreaPadding(.top, UIConstants.topPadding)
            .pauseButton()
    }
}

#Preview {
    CheckScanOverlay(arViewModel: ARViewModel())
}
