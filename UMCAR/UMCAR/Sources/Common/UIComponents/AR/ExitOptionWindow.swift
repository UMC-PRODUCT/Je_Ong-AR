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
        static let pauseViewShadowOffset: CGFloat = 8
        static let leftText: String = "계속하기"
        /// 동작이 "종료하고 처음 화면으로"라 관람객 기준 문구로 맞춘다.
        /// "다시 시작"은 지금 체험을 이어서 재시작하는 것으로 읽힌다.
        static let rightText: String = "체험 종료"
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
        .buttonStyle(.plain)
    }
    
    
    private func makeBtn(image: ImageResource, btnText: String) -> some View {
        VStack {
            Image(image)
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Color.grey000)
                .frame(width: ExitOptionWindowConstants.imageSize, height: ExitOptionWindowConstants.imageSize)
                .frame(width: ExitOptionWindowConstants.btnSize, height: ExitOptionWindowConstants.btnSize)
                // 반투명 패널 위에 얹히는 유리라 tint 로 대비를 확보한다.
                .mainButtonGlass(tint: .indigo500, cornerRadius: ExitOptionWindowConstants.cornerRadius)
            
            Text(btnText)
                .appFont(.title1, weight: .semibold, color: .grey900)
        }
    }
}

#Preview {
    ExitOptionWindow(onContinue: {})
}
