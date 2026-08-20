//
//  ARViewModel.swift
//  UMCAR
//
//  Created by 임영택 on 7/29/25.
//

import Foundation
import ARCore

@Observable
class ARViewModel {
    // ARCore에서 요청하는 프로퍼티
    
    /// 인식한 평면 수
    var currentDetectedPlanes: Int = 0
    
    /// 현재 라이프 카운트 수
    var currentLifeCounts: Int = 5 {
        didSet {
            if currentLifeCounts == 0 {
                gamePhase = .finished
            }
        }
    }
    
    /// 현재 획득 점수
    var currentGameScore: Int = 0
    
    /// 현재 완료된 카드 수
    var numberOfFinishedCards: Int = 0
    
    /// 현재 게임 페이즈
    var gamePhase: GamePhase = .initialized
    
    /// 카드 돌리기 트리거
    var triggerFlipCard = false
    
    /// 뒤집혀진 카드 ID
    var flippedCardId: UUID?
    
    /// 제출된 카드 ID에 대한 채점 정보
    var cardSubmissions: [UUID: GameCardSubmission] = [:]
    
    var triggerOpenPortal = false
    var triggerScanStart = false
    var triggerPlaceCards = false
    var triggerSubmitAccuracy: (UUID, Float)?
    
    var arError: Error?
}

// User Intents
extension ARViewModel {
    func startButtonTapped() {
        triggerScanStart = true
    }
    
    func flipCardButtonTapped() {
        triggerFlipCard = true
    }
    
    func placeCardsButtonTapped() {
        triggerPlaceCards = true
    }
}
