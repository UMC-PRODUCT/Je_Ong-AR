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
    
    func placeCardsButtonTapped() {
        triggerPlaceCards = true
    }
}
