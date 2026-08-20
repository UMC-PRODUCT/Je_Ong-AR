//
//  AccuracyType.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/24/25.
//

import Foundation
import SwiftUI

enum AccuracyType {
    case btnMic
    case recording
    case success
    case failure
    
    var text: String {
        switch self {
        case .btnMic:
            return "마이크 버튼을 눌러 따라해보세요"
        case .recording:
            return "지금 말하세요!"
        case .success:
            return "아주 잘했어요!"
        case .failure:
            return "다시 한번 해볼까요?"
        }
    }
    
    var image: ImageResource? {
        switch self {
        case .btnMic:
            return nil
        case .recording:
            return nil
        case .success:
            return .greenCheck
        case .failure:
            return .redFailure
        }
    }
    
    var accuracyFont: Font {
        return .semibold24
    }
    
    var reactionTextFont: Font {
        return .bold20
    }
    
    var accuracyColor: Color {
        switch self {
        case .btnMic:
            return .green09
        case .recording:
            return .green09
        case .success:
            return .green03
        case .failure:
            return .red00
        }
    }
    
    var reactionTextColor: Color {
        switch self {
        case .btnMic:
            return .green09
        case .recording:
            return .green09
        case .success:
            return .green11
        case .failure:
            return .red06
        }
    }
}
