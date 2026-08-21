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
        return .app(.largeTitle, weight: .semibold)
    }
    
    var color: Color {
        switch self {
        case .restart:
            return .grey000
        case .cardSprinkle(let onOff), .openPotal(let onOff), .start(let onOff):
            return onOff ? .grey000 : .grey500
        }
    }
    
    var bgColor: Color {
        switch self {
        case .restart:
            return .indigo500
        case .cardSprinkle(let onOff), .openPotal(let onOff), .start(let onOff):
            return onOff ? .indigo500 : .grey200
        }
    }
    
    var btnHeight: CGFloat {
        return 87
    }
}
