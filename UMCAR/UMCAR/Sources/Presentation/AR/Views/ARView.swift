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
    @State var detailCardViewModel: DetailCardViewModel = .init()
    
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
            currentLifeCounts: $arViewModel.currentLifeCounts,
            currentGameScore: $arViewModel.currentGameScore,
            numberOfFinishedCards: $arViewModel.numberOfFinishedCards,
            flippedCardId: $arViewModel.flippedCardId,
            cardSubmissions: $arViewModel.cardSubmissions,
            triggerScanStart: $arViewModel.triggerScanStart,
            triggerCreatePortal: $arViewModel.triggerOpenPortal,
            triggerPlaceCards: $arViewModel.triggerPlaceCards,
            triggerSubmitAccuracy: $arViewModel.triggerSubmitAccuracy,
            triggerFlipCard: $arViewModel.triggerFlipCard
        )
        .overlay {
            Group {
                switch arViewModel.gamePhase {
                case .initialized:
                    StartOverlay(arViewModel: arViewModel)
                case .scanning, .scanned, .portalCreated:
                    CheckScanOverlay(arViewModel: arViewModel, allPlanesDetected: allPlanesDetected)
                case .playing:
                    if !arViewModel.showingWordDetailCard {
                        PlayingGameOverlay(arViewModel: arViewModel)
                            .environmentObject(container)
                    } else if let currentSession = selectedGameSession {
                        OnShowingCardOverlay(arViewModel: arViewModel, detailCardViewModel: detailCardViewModel, currentSession: currentSession)
                            .environmentObject(container)
                    }
                case .finished:
                    if let selectedGameSession {
                        FinishedOverlay(gameSessionModel: selectedGameSession, currentLifeCounts: arViewModel.currentLifeCounts)
                    }
                default:
                    EmptyView()
                }
            }
        }
        .onChange(of: arViewModel.flippedCardId) { _, newId in
            if let id = newId {
                detailCardViewModel.word = allCards.first(where: { $0.id == id })
            }
        }
        .onChange(of: arViewModel.numberOfFinishedCards) { _, newValue in
            if newValue == gameCards.count {
                arViewModel.gamePhase = .finished
                
                saveScore()
                saveSuccessCount()
            }
        }
        .onChange(of: arViewModel.showingWordDetailCard) { _, newValue in
            // 단어 창이 닫힐 떄 이전 점수를 초기화한다
            if !newValue {
                detailCardViewModel.lastPassed = false
                detailCardViewModel.accuracyType = .btnMic
                detailCardViewModel.accuracyPercent = 0
            }
        }
        .onChange(of: arViewModel.cardSubmissions) { _, newValue in
            guard let flippedId = arViewModel.flippedCardId else {
                print("cardSubmissions changed but no flipped card")
                return
            }

            guard let submission = newValue[flippedId] else {
                print("cardSubmissions changed but not for current card")
                return
            }

            detailCardViewModel.accuracyType = submission.isPassed ? .success : .failure
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
    }
}

extension ARView {
    private func saveScore() {
        guard let selectedGameSession,
              let selectedLevel else { return }
        
        // 점수 저장
        selectedGameSession.score = arViewModel.currentGameScore
        modelContext.insert(selectedGameSession)
        try? modelContext.save()
        print("점수 저장 완료: \(arViewModel.currentGameScore)")
        
        // 레벨 저장
        let bestScore = selectedLevel.bestScore
        if arViewModel.currentGameScore > bestScore {
            selectedLevel.bestScore = arViewModel.currentGameScore
            print("최고 점수 갱신 완료: \(arViewModel.currentGameScore)")
        }
            
        try? modelContext.save()
    }
    
    private func saveSuccessCount() {
        guard let selectedLevel else { return }
        
        let descriptor = FetchDescriptor<GameSessionModel>()
        if let gameSessions = try? modelContext.fetch(descriptor) {
            var allUsedCardIDs = Set<UUID>()
            
            gameSessions
                .filter{ session in
                    session.level.id == selectedLevel.id
                }
                .forEach { model in
                    for usedCard in model.usedCards {
                        let cardID = usedCard.card.id
                        allUsedCardIDs.insert(cardID)
                    }
                }
            
            selectedLevel.successCount = allUsedCardIDs.count
            try? modelContext.save()
        }
    }
}
