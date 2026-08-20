//
//  IconButtonType.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/22/25.
//

import Foundation
import SwiftUI

enum IconButtonType {
    case back
    case exit
    case close
    case sound
    case mic
    case aim
    case pause
    case target
    case micStop
    
    var image: ImageResource {
        switch self {
        case .back:
            return .back
        case .exit:
            return .exit
        case .close:
            return .close
        case .sound:
            return .sound
        case .mic:
            return .mic
        case .aim:
            return .aim
        case .pause:
            return .pause
        case .target:
            return .targetBtn
        case .micStop:
            return .micStop
        }
    }
    
    var btnSize: (CGFloat, CGFloat) {
        return (96, 90)
    }
    
    var bgColor: Color {
        return .green02
    }
    
}
