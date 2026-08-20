//
//  StartOverlay.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/28/25.
//

import SwiftUI

struct StartOverlay: View {
    @Bindable var arViewModel: ARViewModel
    
    // MARK: - Constants
    fileprivate enum StartOverlayConstants {
        static let opacity: Double = 0.4
        static let guidPadding: CGFloat = 222
        static let cornerRadius: CGFloat = 20
        static let guideHeight: CGFloat = 67
        static let startBtnShadowOffset: CGFloat = 6
        static let shadowOffset: CGFloat = 6
        static let guideMessage: String = "준비가 되었다면 시작해볼까요?"
    }
    var body: some View {
        ZStack {
            Color.black.opacity(StartOverlayConstants.opacity).ignoresSafeArea()
        }
        .overlay(alignment: .center, content: {
            guideText
        })
        .overlay(alignment: .bottom, content: {
            withAnimation(.easeInOut) {
                MainButton(buttonType: .text(.start(onOff: true)), action: {
                    arViewModel.startButtonTapped()
                }, shadowOffset: StartOverlayConstants.startBtnShadowOffset)
                .safeAreaPadding(.horizontal, UIConstants.horizonBtnPadding)
                .safeAreaPadding(.bottom, UIConstants.bottomPadding)
            }
        })
        .safeAreaPadding(.top, UIConstants.topPadding)
        .navigationBarBackButtonHidden(true)
    }
    
    private var guideText: some View {
        ZStack {
            RoundedRectangle(cornerRadius: StartOverlayConstants.cornerRadius)
                .fill(Material.ultraThin)
                .frame(height: StartOverlayConstants.guideHeight)
                .whiteShadow()
            
            Text(StartOverlayConstants.guideMessage)
                .appFont(.title2, weight: .semibold, color: .grey900)
        }
        .safeAreaPadding(.horizontal, StartOverlayConstants.guidPadding)
    }
}

#Preview {
    StartOverlay(arViewModel: ARViewModel())
}
