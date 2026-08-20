//
//  LevelType.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/28/25.
//

import Foundation
import SwiftUI

enum LevelType: String, Codable, Hashable, CaseIterable {
    case easy = "Easy"
    case normal = "Normal"
    case hard = "Hard"
    
    var color: Color {
        switch self {
        case .easy:
            return .green00
        case .normal:
            return .yellow00
        case .hard:
            return .red05
        }
    }
    
    var fontColor: Color {
        switch self {
        case .easy:
            return .green10
        case .normal:
            return .yellow03
        case .hard:
            return .red04
        }
    }
    
    var buttonStrokeColor: Color {
        switch self {
        case .easy:
            return .green07
        case .normal:
            return .yellow04
        case .hard:
            return .red00
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .easy:
            return .levelTappedGreen
        case .normal:
            return .levelTappedYellow
        case .hard:
            return .levelTappedRed
        }
    }
    
    var numericValue: Int {
        switch self {
        case .easy:
            return 0
        case .normal:
            return 1
        case .hard:
            return 2
        }
    }
    
    static func from(numericValue: Int) -> LevelType? {
        switch numericValue {
        case 1:
            return .easy
        case 2:
            return .normal
        case 3:
            return .hard
        default:
            return nil
        }
    }
}
