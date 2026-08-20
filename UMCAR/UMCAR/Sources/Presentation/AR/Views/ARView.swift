//
//  ARView.swift
//  UMCAR
//
//  Created by 임영택 on 7/29/25.
//

import SwiftUI
import ARCore
import Dependency

struct ARView: View {
    @EnvironmentObject var container: DIContainer
    
    // MARK: - View Model
    @State var arViewModel: ARViewModel = .init()
    
    // MARK: - 게임 세팅을 위한 프로퍼티
    /// 앞면 이미지 타이틀 폰트
    let titleFont: UIFont = UMCARFontFamily.NPSFont.extraBold.font(size: 64)
    /// 앞면 이미지 서브타이틀 폰트
    let subtitleFont: UIFont = UMCARFontFamily.NPSFont.extraBold.font(size: 32)
    
    var body: some View {
        ARContainer(
            gameSettings: .init(
                gameCards: TechCard.all,
                fontSetting: .init(
                    title: titleFont,
                    subtitle: subtitleFont
                )
            ),
            exhibitPhase: $arViewModel.exhibitPhase,
            arError: $arViewModel.arError,
            triggerScanStart: $arViewModel.triggerScanStart
        )
        .overlay {
            Group {
                switch arViewModel.exhibitPhase {
                case .initialized:
                    StartOverlay(arViewModel: arViewModel)
                case .scanning:
                    CheckScanOverlay(arViewModel: arViewModel)
                case .browsing:
                    PlayingGameOverlay(arViewModel: arViewModel)
                        .environmentObject(container)
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
    }
}

