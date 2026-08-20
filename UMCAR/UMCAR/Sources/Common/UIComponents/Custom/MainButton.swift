//
//  MainButton.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/22/25.
//

import SwiftUI

/// 앱 전체적으로 사용하는 버튼 정의
struct MainButton: View {
    // MARK: - Property
    let buttonType: ButtonType
    let action: () -> Void
    let shadowOffset: CGFloat
    
    // MARK: - Constants
    fileprivate enum MainButtonConstant {
        static let cornerRadius: CGFloat = 30
    }
    
    // MARK: - Init
    init(buttonType: ButtonType, action: @escaping () -> Void, shadowOffset: CGFloat) {
        self.buttonType = buttonType
        self.action = action
        self.shadowOffset = shadowOffset
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            action()
        }, label: {
            ZStack {
                RoundedRectangle(cornerRadius: MainButtonConstant.cornerRadius)
                    .fill(buttonType.bgColor)
                    .frame(maxWidth: buttonType.width == nil ? .infinity : nil)
                    .frame(width: buttonType.width, height: buttonType.height)
                    .mainButtonShadow(shadowColor: buttonType.shadowColor, yOffset: shadowOffset)
                
                buttonStyle
            }
        })
    }
    
    // MARK: - ButtonStyle
    /// 버튼 스타일 분기
    @ViewBuilder
    private var buttonStyle: some View {
        switch buttonType {
        case .text(let type):
            textView(type: type)
        case .icon(let type):
            imaegView(type: type)
        }
    }
    
    /// 버튼 위 텍스트 뷰
    /// - Parameter type: 텍스트 버튼 타입
    /// - Returns: 텍스트 반환
    private func textView(type: TextButtonType) -> some View {
        Text(type.text)
            .font(type.font)
            .foregroundStyle(type.color)
            .frame(height: type.btnHeight)
    }
    
    /// 이미지 뷰 반환
    /// - Parameter type: 이미지 타입
    /// - Returns: 뷰 반환
    private func imaegView(type: IconButtonType) -> some View {
        Image(type.image)
            .fixedSize()
    }
}
