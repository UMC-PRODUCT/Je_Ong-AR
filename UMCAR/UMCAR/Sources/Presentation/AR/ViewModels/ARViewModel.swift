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
    
    /// 현재 게임 페이즈
    var gamePhase: GamePhase = .initialized
    
    /// 카드 돌리기 트리거
    var triggerFlipCard = false
    
    /// 뒤집혀진 카드 ID
    var flippedCardId: UUID?
    
    var triggerOpenPortal = false
    var triggerScanStart = false
    var triggerPlaceCards = false
    
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
