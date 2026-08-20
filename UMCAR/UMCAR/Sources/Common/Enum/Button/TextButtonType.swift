//
//  ButtonType.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/22/25.
//

import Foundation
import SwiftUI

enum TextButtonType {
    case start(onOff: Bool)
    case cardSprinkle(onOff: Bool)
    case openPotal(onOff: Bool)
    case restart
    

    var text: String {
        switch self {
        case .start:
            return "시작하기"
        case .cardSprinkle:
            return "저 너머 세상엔..?"
        case .openPotal:
            return "단어 세상 포탈 열기!"
        case .restart:
            return "다시 도전하기!"
        }
    }
    
    var font: Font {
        return .bold40
    }
    
    var color: Color {
        switch self {
        case .restart:
            return .green09
        case .cardSprinkle(let onOff), .openPotal(let onOff), .start(let onOff):
            return onOff ? .green09 : .offBtn
        }
    }
    
    var bgColor: Color {
        switch self {
        case .restart:
            return .green02
        case .cardSprinkle(let onOff), .openPotal(let onOff), .start(let onOff):
            return onOff ? .green02 : .gray01
        }
    }
    
    var btnHeight: CGFloat {
        return 87
    }
    
    var shadowColor: Color {
        switch self {
        case .cardSprinkle(let onOff), .openPotal(let onOff), .start(let onOff):
            return onOff ? .greenShadow : .offStartBtn
        case .restart:
            return .greenShadow
        }
    }
}
