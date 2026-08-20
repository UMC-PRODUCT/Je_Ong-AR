//
//  GameModelMapper.swift
//  UMCAR
//
//  Created by 임영택 on 7/29/25.
//

import Foundation
import ARCore
import UIKit

struct GameModelMapper {
    static func toGameModel(_ cardModel: CardModel) -> GameCard {
        .init(
            id: cardModel.id,
            imageName: cardModel.imageName,
            wordKor: cardModel.wordKor,
            wordEng: cardModel.wordEng,
            image: UIImage(named: cardModel.imageName) ?? UIImage(systemName: "questionmark.circle.dashed")!,
            isBoss: false
        )
    }
}
