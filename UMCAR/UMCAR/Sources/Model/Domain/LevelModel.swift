//
//  LevelModel.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/21/25.
//

import Foundation
import SwiftUI
import SwiftData

/// 카테고리에 관계를 갖는 레벨 모델
@Model
final class LevelModel {
    @Attribute(.unique) var id: UUID
    var levelNumber: LevelType
    var bestScore: Int
    var successCount: Int
    
    @Relationship(inverse: \CategoryModel.levels) var category: CategoryModel
    @Relationship(deleteRule: .cascade) var sessions: [GameSessionModel] = []
    @Relationship(deleteRule: .cascade) var cards: [CardModel] = []
    
    init(id: UUID = UUID(), levelNumber: LevelType, bestScore: Int = 0, successCount: Int = 0, category: CategoryModel) {
        self.id = id
        self.levelNumber = levelNumber
        self.bestScore = bestScore
        self.successCount = successCount
        self.category = category
    }
}
