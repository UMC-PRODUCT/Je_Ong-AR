//
//  FinishedOverlay.swift
//  UMCAR
//
//  Created by 임영택 on 7/29/25.
//

import SwiftUI

struct FinishedOverlay: View {
    let gameSessionModel: GameSessionModel
    let currentLifeCounts: Int
    
    private var isGameSuccess: Bool {
        return currentLifeCounts > 0
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
        }
        .overlay(alignment: .center, content: {
            if isGameSuccess {
                CompleteWindow(model: gameSessionModel)
                    .navigationBarBackButtonHidden(true)
            } else {
                FailureWindow(model: gameSessionModel)
                    .navigationBarBackButtonHidden(true)
            }
        })
        .safeAreaPadding(.horizontal, UIConstants.horizontalPading)
        
    }
}
