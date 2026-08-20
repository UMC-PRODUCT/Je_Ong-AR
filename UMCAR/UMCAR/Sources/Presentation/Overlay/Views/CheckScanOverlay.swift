//
//  CheckScanOverlay.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/29/25.
//

import SwiftUI
import Dependency

struct CheckScanOverlay: View {
    @Bindable var arViewModel: ARViewModel
    @EnvironmentObject var container: DIContainer
    let allPlanesDetected: Bool
    
    fileprivate enum CheckScanOverlayConstants {
        static let shadowOffset: CGFloat = 6
    }
    
    var body: some View {
        Color.clear
            .overlay(alignment: .top, content: {
                ChekScanCamera(currentCount: $arViewModel.currentDetectedPlanes)
            })
            .overlay(alignment: .bottom, content: {
                Group {
                    if arViewModel.gamePhase == .portalCreated {
                        MainButton(buttonType: .text(.cardSprinkle(onOff: true)), action: {
                            arViewModel.placeCardsButtonTapped()
                        }, shadowOffset: CheckScanOverlayConstants.shadowOffset)
                    }
                    else {
                        MainButton(buttonType: .text(.openPotal(onOff: allPlanesDetected)), action: {
                            arViewModel.triggerOpenPortal = true
                        }, shadowOffset: CheckScanOverlayConstants.shadowOffset)
                        .disabled(!allPlanesDetected)
                    }
                }
                .safeAreaPadding(.horizontal, UIConstants.horionLongTextPadding)
            })
            .navigationBarBackButtonHidden(true)
            .safeAreaPadding(.trailing, UIConstants.naviLeadingPadding)
            .safeAreaPadding(.bottom, UIConstants.bottomPadding)
            .safeAreaPadding(.top, UIConstants.topPadding)
            .pauseButton()
    }
}

#Preview {
    CheckScanOverlay(arViewModel: ARViewModel(), allPlanesDetected: true)
}
