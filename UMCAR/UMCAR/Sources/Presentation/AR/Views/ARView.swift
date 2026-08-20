//
//  ARView.swift
//  UMCAR
//
//  Created by 임영택 on 7/29/25.
//

import SwiftUI
import ARCore
import SwiftData
import Dependency

struct ARView: View {
    // MARK: - SwiftData
    @Environment(\.modelContext) var modelContext
    let levelModelID: UUID
    @Query var levels: [LevelModel]
    @Query var gameSessions: [GameSessionModel]
    @Query var allCards: [CardModel]
    @EnvironmentObject var container: DIContainer
    
    var selectedLevel: LevelModel? {
        levels.first { levelModel in
            levelModel.id == levelModelID
        }
    }
    
    var selectedGameSession: GameSessionModel? {
        gameSessions.first { gameSessionModel in
            gameSessionModel.level.id == levelModelID
        }
    }
    
    var allPlanesDetected: Bool {
        arViewModel.currentDetectedPlanes == gameCards.count
    }
    
    // ARCore 데이터 모델
    var gameCards: [GameCard] {
        if let selectedLevel {
            let everyCardInLevel = selectedLevel.cards.compactMap { GameModelMapper.toGameModel($0) }
            let randomCards = everyCardInLevel.shuffled().prefix(5)
            return Array(randomCards)
        }
        
        return []
    }
    
    // MARK: - View Model
    @State var arViewModel: ARViewModel = .init()
    
    // MARK: - 게임 세팅을 위한 프로퍼티
    /// 최소 평면 사이즈
    let minimumSizeOfPlane: Float = 0.5
    /// 앞면 이미지 타이틀 폰트
    let titleFont: UIFont = UMCARFontFamily.NPSFont.extraBold.font(size: 64)
    /// 앞면 이미지 서브타이틀 폰트
    let subtitleFont: UIFont = UMCARFontFamily.NPSFont.extraBold.font(size: 32)
    
    var body: some View {
        ARContainer(
            gameSettings: .init(
                gameCards: gameCards,
                minimumSizeOfPlane: minimumSizeOfPlane,
                fontSetting: .init(
                    title: titleFont,
                    subtitle: subtitleFont
                )
            ),
            gamePhase: $arViewModel.gamePhase,
            arError: $arViewModel.arError,
            currentDetectedPlanes: $arViewModel.currentDetectedPlanes,
            triggerScanStart: $arViewModel.triggerScanStart,
            triggerCreatePortal: $arViewModel.triggerOpenPortal,
            triggerPlaceCards: $arViewModel.triggerPlaceCards
        )
        .overlay {
            Group {
                switch arViewModel.gamePhase {
                case .initialized:
                    StartOverlay(arViewModel: arViewModel)
                case .scanning, .scanned, .portalCreated:
                    CheckScanOverlay(arViewModel: arViewModel, allPlanesDetected: allPlanesDetected)
                case .playing:
                    PlayingGameOverlay(arViewModel: arViewModel)
                        .environmentObject(container)
                default:
                    EmptyView()
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
    }
}

