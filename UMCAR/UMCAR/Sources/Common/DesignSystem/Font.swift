//
//  Font.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/21/25.
//

import SwiftUI

// MARK: - AppFont

/// Big-Dipper 디자인 시스템의 타이포그래피 스케일.
public enum AppFont {
    case largeTitle
    case title1
    case title2
    case title3
    case body
    case callout
    case subheadline
    case footnote
    case caption1
    case caption2

    public var size: CGFloat {
        switch self {
        case .largeTitle:  return 34
        case .title1:      return 28
        case .title2:      return 22
        case .title3:      return 20
        case .body:        return 17
        case .callout:     return 16
        case .subheadline: return 15
        case .footnote:    return 13
        case .caption1:    return 12
        case .caption2:    return 11
        }
    }

    public var lineHeight: CGFloat {
        switch self {
        case .largeTitle:  return 41.14
        case .title1:      return 33.88
        case .title2:      return 27.94
        case .title3:      return 25.00
        case .body:        return 23.46
        case .callout:     return 20.96
        case .subheadline: return 19.95
        case .footnote:    return 17.94
        case .caption1:    return 15.96
        case .caption2:    return 12.98
        }
    }

    public var lineSpacing: CGFloat { lineHeight - size }

    public var textStyle: Font.TextStyle {
        switch self {
        case .largeTitle:  return .largeTitle
        case .title1:      return .title
        case .title2:      return .title2
        case .title3:      return .title3
        case .body:        return .body
        case .callout:     return .callout
        case .subheadline: return .subheadline
        case .footnote:    return .footnote
        case .caption1:    return .caption
        case .caption2:    return .caption2
        }
    }
}

// MARK: - AppFontWeight

public enum AppFontWeight {
    case regular
    case medium
    case semibold

    public var fontConvertible: UMCARFontConvertible {
        switch self {
        case .regular:  return UMCARFontFamily.Pretendard.regular
        case .medium:   return UMCARFontFamily.Pretendard.medium
        case .semibold: return UMCARFontFamily.Pretendard.semiBold
        }
    }

    /// Tuist 가 만든 컨버터블은 UIFont 를 만들 때만 폰트를 등록한다.
    /// `Font.custom(_:size:relativeTo:)` 는 이름만 받으므로, 여기서 한 번
    /// UIFont 를 찍어 등록을 강제한 뒤 그 PostScript 이름을 넘긴다.
    public var fontName: String { fontConvertible.font(size: 1).fontName }

    public var swiftUIWeight: Font.Weight {
        switch self {
        case .regular:  return .regular
        case .medium:   return .medium
        case .semibold: return .semibold
        }
    }
}

// MARK: - Font Extension

public extension Font {
    static func app(_ style: AppFont, weight: AppFontWeight = .regular) -> Font {
        .custom(weight.fontName, size: style.size, relativeTo: style.textStyle)
    }

    static func app(size: CGFloat, weight: AppFontWeight = .medium) -> Font {
        .custom(weight.fontName, size: size)
    }
}

// MARK: - View Extension

public extension View {
    @ViewBuilder
    func appFont(
        _ style: AppFont,
        weight: AppFontWeight = .regular,
        color: Color? = nil
    ) -> some View {
        let view = self
            .font(.app(style, weight: weight))
            .lineSpacing(style.lineSpacing)
        if let color {
            view.foregroundStyle(color)
        } else {
            view
        }
    }
}
