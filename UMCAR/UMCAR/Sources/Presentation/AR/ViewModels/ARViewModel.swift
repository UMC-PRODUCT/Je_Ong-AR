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
    
    /// 인식한 카드 수
    var detectedCardCount: Int = 0
    
    /// 열린 패널의 카드 id. 없으면 nil
    var selectedCardID: String?
    
    /// 현재 전시 페이즈
    var exhibitPhase: ExhibitPhase = .initialized
    
    var triggerScanStart = false
    
    var arError: Error?
}

// User Intents
extension ARViewModel {
    func startButtonTapped() {
        triggerScanStart = true
    }
    
}
