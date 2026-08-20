//
//  UsedCardModel.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/21/25.
//

import Foundation
import SwiftData

/// N:M 관계 중간 모델
@Model
final class UsedCardModel {
    @Relationship(inverse: \GameSessionModel.usedCards) var session: GameSessionModel
    @Relationship var card: CardModel
    
    init(session: GameSessionModel, card: CardModel) {
        self.session = session
        self.card = card
    }
}
