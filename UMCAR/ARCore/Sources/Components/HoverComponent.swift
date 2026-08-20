//
//  DynamicTextureComponent.swift
//  ARCore
//
//  Created by 임영택 on 7/24/25.
//

import RealityKit
import UIKit

struct HoverComponent: Component {
    // MARK: Properties
    /// 카드 데이터
    let cardData: GameCard?
    
    /// 호버 상태인지 여부
    var isHovering: Bool
    
    /// 텍스쳐에 들어갈 AttributedString
    var attributedText: NSAttributedString {
        let wordEng = NSAttributedString(
            string: (cardData?.wordEng ?? "N/A") + "\n",
            attributes: [
                .foregroundColor: UIColor.black,
                .font: UIFont.systemFont(ofSize: 64, weight: .bold)
            ]
        )
        let wordKor = NSAttributedString(
            string: cardData?.wordKor ?? "N/A",
            attributes: [
                .foregroundColor: UIColor.black,
                .font: UIFont.systemFont(ofSize: 48, weight: .medium)
            ]
        )

        let combined = NSMutableAttributedString()
        combined.append(wordEng)
        combined.append(wordKor)
        
        return combined
    }
    
    init(cardData: GameCard?, isHovering: Bool = false) {
        self.cardData = cardData
        self.isHovering = isHovering
    }
}
