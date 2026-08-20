//
//  GameSessionModel.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/21/25.
//

import SwiftData
import SwiftUI

/// 카드를 띄우고 영어 단어 발음 후 획득 포인트
@Model
final class GameSessionModel {
    @Attribute(.unique) var id: UUID
    var playedAt: Date
    var score: Int
    
    @Relationship var level: LevelModel
    @Relationship(deleteRule: .cascade) var usedCards: [UsedCardModel] = []
    
    init(id: UUID = UUID(), playedAt: Date = .now, score: Int, level: LevelModel) {
        self.id = id
        self.playedAt = playedAt
        self.score = score
        self.level = level
    }
}
