//
//  PlayingGameOverlay.swift
//  UMCAR
//
//  Created by 임영택 on 7/29/25.
//

import SwiftUI
import Dependency
import ARCore

/// 플레잉 중 오버레이
struct PlayingGameOverlay: View {
    @Bindable var arViewModel: ARViewModel
    @EnvironmentObject var container: DIContainer
    
    fileprivate enum PlayingGameConstants {
        static let guideWidth: CGFloat = 749
        static let guideHeight: CGFloat = 67
        static let horizonPadding: CGFloat = 40
        static let cornerRadius: CGFloat = 20
        static let guideText: String = "가운데의 조준점을 카드 위에 대고 버튼을 눌러주세요"
        static let bottomPadding: CGFloat = 177
        static let dropShadowSize: CGFloat = 4
        static let shadowOffset: CGFloat = 6
    }
    
    var body: some View {
        ZStack {
            Color.clear
        }
        .overlay(alignment: .topLeading, content: {
        })
        .overlay(alignment: .bottom, content: {
            bottonGuide
                .padding(.bottom, PlayingGameConstants.bottomPadding - UIConstants.bottomPadding)
        })
        .safeAreaPadding(.top, UIConstants.topPadding)
        .safeAreaPadding(.horizontal, PlayingGameConstants.horizonPadding)
        .safeAreaPadding(.bottom, UIConstants.bottomPadding)
        .navigationBarBackButtonHidden(true)
        .pauseButton()
    }
    
    
    
    private var bottonGuide: some View {
        ZStack {
            RoundedRectangle(cornerRadius: PlayingGameConstants.cornerRadius)
                .fill(Material.ultraThin)
                .clipShape(RoundedRectangle(cornerRadius: PlayingGameConstants.cornerRadius))
                .frame(width: PlayingGameConstants.guideWidth, height: PlayingGameConstants.guideHeight)
                .glassShadow(PlayingGameConstants.dropShadowSize)
            
            Text(PlayingGameConstants.guideText)
                .font(.semibold24)
                .foregroundStyle(Color.black01)
        }
    }
    
    
    private func checkBtnAction() -> Bool {
        return arViewModel.currentDetectedPlanes > 0 ? true : false
    }
    
}


#Preview {
    PlayingGameOverlay(arViewModel: .init(), container: .init())
}
