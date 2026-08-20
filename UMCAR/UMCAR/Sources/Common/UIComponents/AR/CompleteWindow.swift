//
//  CompleteWindowView.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/24/25.
//

import Foundation
import SwiftUI
import Dependency

struct CompleteWindow: View {
    let model: GameSessionModel
    @EnvironmentObject var container: DIContainer
    
    fileprivate enum CompleteWindowConstants {
        static let maxWidth: CGFloat = 749
        static let vstackWidth: CGFloat = 419
        static let safeAreaVerticalPadding: CGFloat = 203
        static let safeAreaHorionPadding: CGFloat = 222
        static let mainVerticalPadding: CGFloat = 40
        static let mainHorizonPadding: CGFloat = 135
        static let verticalPadding: CGFloat = 14
        static let horizonPadding: CGFloat = 30
        static let cornerRadius: CGFloat = 30
        static let titleOutline: CGFloat = 6
        static let scoreOutline: CGFloat = 3
        static let shadowOffset: CGFloat = 8
        static let title: String = "Clear!"
        static let subTitle: String = "카테고리로 돌아가기"
    }
    
    var body: some View {
            VStack {
                title
                score
                MainButton(buttonType: .text(.restart), action: {
                    container.restartGame()
                }, shadowOffset: CompleteWindowConstants.shadowOffset)
            }
            .frame(width: CompleteWindowConstants.vstackWidth)
            .padding(.vertical, CompleteWindowConstants.mainVerticalPadding)
            .padding(.horizontal, CompleteWindowConstants.mainHorizonPadding)
            .background {
                RoundedRectangle(cornerRadius: CompleteWindowConstants.cornerRadius)
                    .fill(Color.white01)
                    .opacity(0.65)
                    .background(Material.ultraThin)
                    .clipShape(RoundedRectangle(cornerRadius: CompleteWindowConstants.cornerRadius))
                    .grayShadow()
            }
    }
    
    private var title: some View {
        Text(CompleteWindowConstants.title)
            .font(.semibold80)
            .foregroundStyle(Color.green07)
            .customOutline(width: CompleteWindowConstants.titleOutline, color: .white)
    }
    
    private var score: some View {
        HStack(spacing: 36, content: {
            Image(.bin)
            
            Text("\(model.score)")
                .font(.poetsen(.regular, size: 80))
                .foregroundStyle(Color.gray04)
        })
    }
}


#Preview {
    CompleteWindow(model: .init(score: 46, level: .init(levelNumber: .easy, category: .init(imageName: "", nameKor: "1", nameEng: "2"))))
}
