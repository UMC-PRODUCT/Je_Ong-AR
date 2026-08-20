//
//  GameStatus.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/23/25.
//

import SwiftUI

/// 생명 표시 하트
struct LifeHeart: View {
    
    // MARK: - Property
    let currentLife: Int
    let maxCount: Int = 5
    
    // MARK: - Constants
    fileprivate enum GameStatusConstants {
        static let spacing: CGFloat = 12
        static let horizonPadding: CGFloat = 16
    }
    
    
    // MARK: - Init
    init(currentLife: Int) {
        self.currentLife = currentLife
    }
    // MARK: - Body
    var body: some View {
        HStack(alignment: .center, spacing: GameStatusConstants.spacing, content: {
            ForEach(.zero..<maxCount, id: \.self) { index in
                if index < currentLife {
                    Image(.heartIcon)
                } else {
                    Image(.emptyHeart)
                }
            }
        })
        .padding(.horizontal, GameStatusConstants.horizonPadding)
    }
}

#Preview {
    LifeHeart(currentLife: 3)
}
