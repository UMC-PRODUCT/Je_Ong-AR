//
//  PauseButtonModifier.swift
//  UMCAR
//
//  Created by Claude on 8/17/25.
//

import SwiftUI
import Dependency

struct PauseButtonModifier: ViewModifier {
    @EnvironmentObject var container: DIContainer
    @State private var showExitOption = false
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                MainButton(buttonType: .icon(.pause), action: {
                    showExitOption = true
                }, shadowOffset: 6)
                .safeAreaPadding(.top, UIConstants.topPadding)
                .safeAreaPadding(.trailing, UIConstants.naviLeadingPadding)
            }
            .overlay {
                if showExitOption {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            ExitOptionWindow(onContinue: {
                                showExitOption = false
                            })
                            .environmentObject(container)
                        }
                }
            }
    }
}

extension View {
    func pauseButton() -> some View {
        modifier(PauseButtonModifier())
    }
}
