//
//  GameSettings.swift
//  ARCore
//
//  Created by 임영택 on 7/19/25.
//

/// 게임 설정
public struct GameSettings {
    // MARK: - Properties
    
    /// 이번 게임에서 부착할 게임 카드 데이터
    let gameCards: [TechCard]
    
    /// 배치할 카드의 총 개수
    var numberOfCards: Int {
        gameCards.count
    }
    
    public init(gameCards: [TechCard], fontSetting: ARCoreFontSetting) {
        self.gameCards = gameCards
        
        ARCoreFontSystem.shared.configure(with: fontSetting) // 폰트 설정
    }
}
