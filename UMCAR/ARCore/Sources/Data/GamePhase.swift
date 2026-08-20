//
//  GamePhase.swift
//  ARCore
//
//  Created by 임영택 on 7/22/25.
//

import Foundation

/// 게임의 진행 단계를 표현한다
public enum GamePhase {
    /// AR이 초기화만 되고 아무 것도 진행되지 않은 단계
    case initialized
    
    /// 평면을 스캔중인 단계
    case scanning
    
    /// 평면 스캔이 완료된 단계
    case scanned
    
    /// 포탈이 생성중인 단계
    case portalCreating
    
    /// 포탈 생성이 완료된 단계
    case portalCreated
    
    /// 카드가 슝슝 배치중인 단계
    case cardPlacing
    
    /// 카드가 모두 뿌려지고 게임이 진행중인 단계
    case playing
    
    /// 게임이 일시 중단된 단계
    case paused
    
    /// 게임이 클리어된 단계
    case finished
}
