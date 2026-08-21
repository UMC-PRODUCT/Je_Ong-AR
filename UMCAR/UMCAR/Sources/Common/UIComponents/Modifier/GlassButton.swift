//
//  GlassButton.swift
//  UMCAR
//

import SwiftUI

extension View {
    /// 버튼 표면을 Liquid Glass 로 통일한다.
    /// 브랜드 인디고는 tint 로 남기고, 눌림 반응은 `interactive()` 가 유리 자체에서 처리한다
    /// (기존 radius 0 하드 섀도우는 유리의 자체 깊이와 충돌해서 걷어냈다).
    func mainButtonGlass(tint: Color, cornerRadius: CGFloat) -> some View {
        glassEffect(
            .regular.tint(tint).interactive(),
            in: .rect(cornerRadius: cornerRadius)
        )
    }
}
