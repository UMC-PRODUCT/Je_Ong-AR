//
//  Font.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/21/25.
//

import Foundation
import SwiftUI

public extension Font {
    enum UMCARFont {
        case bold
        case extraBold
        case regular
        
        var fontConvertible: UMCARFontConvertible {
            switch self {
            case .bold:
                return UMCARFontFamily.NPSFont.bold
            case .extraBold:
                return UMCARFontFamily.NPSFont.extraBold
            case .regular:
                return UMCARFontFamily.NPSFont.regular
            }
        }
        
        func font(size: CGFloat) -> Font {
            fontConvertible.swiftUIFont(size: size)
        }
    }
    
    enum Poetsen {
        case regular
        
        var fontConvertible: UMCARFontConvertible {
            switch self {
            case .regular:
                return UMCARFontFamily.PoetsenOne.regular
            }
        }
        
        func font(size: CGFloat) -> Font {
            fontConvertible.swiftUIFont(size: size)
        }
    }
    
    static func umcar(_ type: UMCARFont, size: CGFloat) -> Font {
        return type.font(size: size)
    }
    
    static func poetsen(_ type: Poetsen, size: CGFloat) -> Font {
        return type.font(size: size)
    }
    
    // MARK: - ExtraBold
    static var semibold80: Font {
        return .umcar(.extraBold, size: 80)
    }
    
    static var semibold64: Font {
        return .umcar(.extraBold, size: 64)
    }
    
    static var semibold104: Font {
        return .umcar(.extraBold, size: 104)
    }
    
    static var semibold36: Font {
        return .umcar(.extraBold, size: 36)
    }
    
    static var semibold32: Font {
        return .umcar(.extraBold, size: 32)
    }
    
    static var semibold24: Font {
        return .umcar(.extraBold, size: 24)
    }
    
    static var semibold20: Font {
        return .umcar(.extraBold, size: 20)
    }
    
    static var semibold16: Font {
        return .umcar(.extraBold, size: 16)
    }
    
    static var poetsen48: Font {
        return .poetsen(.regular, size: 48)
    }
    
    // MARK: - Bold
    static var bold80: Font {
        return .umcar(.bold, size: 80)
    }
    
    static var bold40: Font {
        return .umcar(.bold, size: 40)
    }
    
    static var bold36: Font {
        return .umcar(.bold, size: 36)
    }
    
    static var bold32: Font {
        return .umcar(.bold, size: 32)
    }
    
    static var bold24: Font {
        return .umcar(.bold, size: 24)
    }
    
    static var bold20: Font {
        return .umcar(.bold, size: 20)
    }
    
    static var bold16: Font {
        return .umcar(.bold, size: 16)
    }
}
