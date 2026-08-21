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
    
    // MARK: - Constants
    fileprivate enum MainButtonConstant {
        static let cornerRadius: CGFloat = 30
    }
    
    // MARK: - Init
    init(buttonType: ButtonType, action: @escaping () -> Void) {
        self.buttonType = buttonType
        self.action = action
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: action) {
            buttonStyle
                .frame(width: buttonType.width, height: buttonType.height)
                .mainButtonGlass(
                    tint: buttonType.bgColor,
                    cornerRadius: MainButtonConstant.cornerRadius
                )
        }
        .buttonStyle(.plain)
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
    }
    
    /// 이미지 뷰 반환
    /// - Parameter type: 이미지 타입
    /// - Returns: 뷰 반환
    private func imaegView(type: IconButtonType) -> some View {
        // 아이콘 PDF 는 옛 초록(#416D3D) 단색 글리프다. 템플릿으로 뽑아
        // 인디고 유리 위에서 흰색으로 찍는다 — 에셋을 다시 그릴 필요가 없다.
        Image(type.image)
            .renderingMode(.template)
            .foregroundStyle(Color.grey000)
            .fixedSize()
    }
}
