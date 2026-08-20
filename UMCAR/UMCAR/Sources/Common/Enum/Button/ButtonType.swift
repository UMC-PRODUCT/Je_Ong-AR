//
//  ButtonType.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/22/25.
//

import Foundation
import SwiftUI

enum ButtonType {
    case text(TextButtonType)
    case icon(IconButtonType)

    var text: String? {
        switch self {
        case .text(let type):
            return type.text
        case .icon:
            return nil
        }
    }

    var image: ImageResource? {
        switch self {
        case .text:
            return nil
        case .icon(let type):
            return type.image
        }
    }

    var font: Font? {
        switch self {
        case .text(let type):
            return type.font
        case .icon:
            return nil
        }
    }

    var color: Color? {
        switch self {
        case .text(let type):
            return type.color
        case .icon:
            return nil
        }
    }

    var bgColor: Color {
        switch self {
        case .text(let type):
            return type.bgColor
        case .icon(let type):
            return type.bgColor
        }
    }

    var width: CGFloat? {
        switch self {
        case .text:
            return 376
        case .icon(let type):
            return type.btnSize.0
        }
    }

    var height: CGFloat {
        switch self {
        case .text(let type):
            return type.btnHeight
        case .icon(let type):
            return type.btnSize.1
        }
    }
    
    var shadowColor: Color {
        switch self {
        case .text(let type):
            return type.shadowColor
        case .icon:
            return .indigo700
        }
    }
}
