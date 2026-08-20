//
//  ExitOption.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/29/25.
//

import SwiftUI
import Dependency

struct ExitOptionWindow: View {
    @EnvironmentObject var container: DIContainer
    let onContinue: () -> Void
    
    fileprivate enum ExitOptionWindowConstants {
        static let cornerRadius: CGFloat = 30
        static let btnHspacing: CGFloat = 80
        static let bgWidth: CGFloat = 502
        static let bgHeight: CGFloat = 308
        static let imageSize: CGFloat = 100
        static let btnSize: CGFloat = 136
        static let btnShadowOffset: CGFloat = 6
        static let pauseViewShadowOffset: CGFloat = 8
        static let leftText: String = "계속하기"
        static let rightText: String = "다시 시작"
    }
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: ExitOptionWindowConstants.cornerRadius)
                .fill(Material.ultraThin)
                .overlay(
                    RoundedRectangle(cornerRadius: ExitOptionWindowConstants.cornerRadius)
                        .fill(Material.ultraThin)
                )
                .pauseGlassShadow(ExitOptionWindowConstants.pauseViewShadowOffset)
                .frame(width: ExitOptionWindowConstants.bgWidth, height: ExitOptionWindowConstants.bgHeight)
            
            btnGroup
        }
    }
    
    private var btnGroup: some View {
        HStack(spacing: ExitOptionWindowConstants.btnHspacing, content: {
            Button(action: {
                onContinue()
            }, label: {
                makeBtn(image: .continue, btnText: ExitOptionWindowConstants.leftText)
            })
            
            Button(action: {
                container.restartSession()
            }, label: {
                makeBtn(image: .exit, btnText: ExitOptionWindowConstants.rightText)
            })
        })
    }
    
    
    private func makeBtn(image: ImageResource, btnText: String) -> some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: ExitOptionWindowConstants.cornerRadius)
                    .fill(Color.indigo500)
                    .frame(width: ExitOptionWindowConstants.btnSize, height: ExitOptionWindowConstants.btnSize)
                    .mainButtonShadow(shadowColor: Color.indigo700, yOffset: ExitOptionWindowConstants.btnShadowOffset)
                
                Image(image)
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Color.grey000)
                    .frame(width: ExitOptionWindowConstants.imageSize, height: ExitOptionWindowConstants.imageSize)
                
            }
            
            Text(btnText)
                .appFont(.title1, weight: .semibold, color: .grey900)
        }
    }
}

#Preview {
    ExitOptionWindow(onContinue: {})
}
