//
//  CompleteWindowView.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/24/25.
//

import Foundation
import SwiftUI
import Dependency

struct FailureWindow: View {
    let model: GameSessionModel
    @EnvironmentObject var container: DIContainer
    
    fileprivate enum CompleteWindowConstants {
        static let maxWidth: CGFloat = 749
        static let vstackWidth: CGFloat = 419
        static let safeAreaVerticalPadding: CGFloat = 203
        static let safeAreaHorionPadding: CGFloat = 222
        static let mainVerticalPadding: CGFloat = 70
        static let mainHorizonPadding: CGFloat = 167
        static let verticalPadding: CGFloat = 30
        static let horizonPadding: CGFloat = 30
        static let cornerRadius: CGFloat = 30
        static let btnVspacing: CGFloat = 26
        static let titleOutline: CGFloat = 4
        static let shadowOffset: CGFloat = 8
        static let title: String = "Game Over!"
        static let subTitle: String = "카테고리로 돌아가기"
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: CompleteWindowConstants.verticalPadding) {
            title
            btnContents
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
            .foregroundStyle(Color.red01)
            .customOutline(width: CompleteWindowConstants.titleOutline, color: .white)
            .lineLimit(1)
            .fixedSize()
    }
    
    private var btnContents: some View {
        VStack(spacing: CompleteWindowConstants.btnVspacing, content: {
            MainButton(buttonType: .text(.restart), action: {
                container.restartGame()
            }, shadowOffset: CompleteWindowConstants.shadowOffset)
        })
    }
}


#Preview {
    FailureWindow(model: .init(score: 46, level: .init(levelNumber: .easy, category: .init(imageName: "", nameKor: "1", nameEng: "2"))))
}
