//
//  GameStatus.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/23/25.
//

import SwiftUI

struct GameStatus: View {
    
    // MARK: - Property
    @Binding var currentScore: Int
    @Binding var currentCard: Int
    @Binding var currentLife: Int
    let maxCount: Int = 5
    
    // MARK: - Constants
    fileprivate enum GameStatusConstants {
        static let verticalPadding: CGFloat = 8
        static let horizonPadding: CGFloat = 16
        static let statusVspacing: CGFloat = 10
        static let cardHspacing: CGFloat = 16
        static let bottomInfoHspacing: CGFloat = 24
        static let scoreLeadingPadding: CGFloat = 24
        static let cornerRadius: CGFloat = 30
        static let binWidth: CGFloat = 40
        static let binHeight: CGFloat = 34
        static let cardBottomSpacing: CGFloat = 0
        static let cardBottomImagePadding: CGFloat = 16
        static let scoreLabelWidth: CGFloat = 94
        static let cardsLabelWidth: CGFloat = 140
        static let dropShadowSize: CGFloat = 6
        static let scoreText: String = "Score"
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: GameStatusConstants.statusVspacing, content: {
            LifeHeart(currentLife: currentLife)
            bottomContents
        })
        .padding(.vertical, GameStatusConstants.verticalPadding)
        .background(Material.ultraThin)
        .clipShape(RoundedRectangle(cornerRadius: GameStatusConstants.cornerRadius))
        .glassShadow(GameStatusConstants.dropShadowSize)
    }
    // MARK: - Bottom
    /// 하단 점수 및 카드 수집 정보
    private var bottomContents: some View {
        HStack(spacing: GameStatusConstants.bottomInfoHspacing, content: {
            scoreText
            currentCardInfo
        })
        .frame(alignment: .leading)
    }
    
    /// 현재 스코어 표시 텍스트
    private var scoreText: some View {
        HStack(spacing: GameStatusConstants.cardBottomSpacing) {
            Image(.bin)
                .resizable()
                .frame(width: GameStatusConstants.binWidth, height: GameStatusConstants.binHeight)
            
            Spacer()
                .frame(width: GameStatusConstants.cardBottomImagePadding)
            
            Text("\(currentScore)")
                .font(.poetsen48)
                .foregroundStyle(Color.black)
                .customOutline(width: 1, color: .white01)
                .frame(width: GameStatusConstants.scoreLabelWidth, alignment: .leading)
        }
        .safeAreaPadding(.leading, GameStatusConstants.scoreLeadingPadding)
    }
    
    /// 카드 현재 수집 정보
    private var currentCardInfo: some View {
        HStack(spacing: GameStatusConstants.cardHspacing, content: {
            Image(.totalCard)
            Text("\(currentCard)/\(maxCount)")
                .font(.poetsen48)
                .foregroundStyle(Color.black01)
                .customOutline(width: 1, color: .white01)
        })
    }
}

#Preview {
    @Previewable @State var currentScore: Int = 2
    @Previewable @State var curentCard: Int = 2
    @Previewable @State var currentLife: Int = 2
    
    GameStatus(currentScore: $currentScore, currentCard: $curentCard, currentLife: $currentLife)
}
