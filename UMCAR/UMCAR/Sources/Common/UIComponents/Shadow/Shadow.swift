//
//  Shadow.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/22/25.
//

import Foundation
import SwiftUI

struct MainButtonShadow: ViewModifier {
    
    let shadowColor: Color
    let yOffset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: shadowColor, radius: 0, x: 0, y: yOffset)
    }
}

struct WhiteButtonShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .gray01, radius: 0, x: 0, y: 4)
    }
}

struct GrayShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .gray01, radius: 0, x: 0, y: 8)
    }
}

struct GrayShadow4: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .gray01, radius: 0, x: 0, y: 4)
    }
}

struct GlassShadow: ViewModifier {
    let ySize: CGFloat
    static let dropShadowColor: Color = Color(red: 224 / 255, green: 224 / 255, blue: 224 / 255) // #E0E0E0
    
    init(_ ySize: CGFloat) {
        self.ySize = ySize
    }
    
    func body(content: Content) -> some View {
        content
            .shadow(color: Self.dropShadowColor, radius: 0, x: 0, y: ySize)
    }
}

struct PauseGlassShadow: ViewModifier {
    let ySize: CGFloat
    static let dropShadowColor: Color = Color(#colorLiteral(red: 0.6980392157, green: 0.6980392157, blue: 0.6980392157, alpha: 1))
    
    init(_ ySize: CGFloat) {
        self.ySize = ySize
    }
    
    func body(content: Content) -> some View {
        content
            .shadow(color: Self.dropShadowColor, radius: 0, x: 0, y: ySize)
    }
}


extension View {
    func mainButtonShadow(shadowColor: Color, yOffset: CGFloat) -> some View {
        self.modifier(MainButtonShadow(shadowColor: shadowColor, yOffset: yOffset))
    }
    
    func whiteShadow() -> some View {
        self.modifier(WhiteButtonShadow())
    }
    
    func grayShadow() -> some View {
        self.modifier(GrayShadow())
    }
    
    func grayShadow4() -> some View {
        self.modifier(GrayShadow4())
    }
    
    /// 조건이 참일 때만 grayShadow를 적용하는 View Modifier
    @ViewBuilder
    func grayShadow(if condition: Bool) -> some View {
        if condition {
            self.grayShadow()
        } else {
            self
        }
    }
    
    
    func glassShadow(_ ySize: CGFloat) -> some View {
        self.modifier(GlassShadow(ySize))
    }
    
    func pauseGlassShadow(_ ySize: CGFloat) -> some View {
        self.modifier(PauseGlassShadow(ySize))
    }
}
