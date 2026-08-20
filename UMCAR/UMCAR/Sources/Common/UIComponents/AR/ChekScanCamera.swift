//
//  ChekScanCamera.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/23/25.
//

import SwiftUI

struct ChekScanCamera: View {
    // MARK: - Property
    @Binding var currentCount : Int
    let maxCount: Int = 5
    
    // MARK: - Constants
    fileprivate enum CheckScanCameraConstants {
        static let mainVspacing: CGFloat = 10
        static let listSpacing: CGFloat = 32
        static let horizonPadding: CGFloat = 63
        static let verticalPadding: CGFloat = 20
        static let cornerRadius: CGFloat = 20
        static let guideText: String = "카메라로 주변을 천천히 찍어서 5개를 채워주세요"
        static let dropShadowSize: CGFloat = 4
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: CheckScanCameraConstants.mainVspacing, content: {
            checkList
            guideText
        })
        .padding(.horizontal, CheckScanCameraConstants.horizonPadding)
        .padding(.vertical, CheckScanCameraConstants.verticalPadding)
        .background(Material.ultraThin)
        .clipShape(RoundedRectangle(cornerRadius: CheckScanCameraConstants.cornerRadius))
        .grayShadow4()
    }
    
    /// 체크 리스트
    private var checkList: some View {
        HStack(spacing: CheckScanCameraConstants.listSpacing, content: {
            ForEach(.zero..<maxCount, id: \.self) { index in
                if index < currentCount {
                    Image(.check)
                } else {
                    Image(.emptyCheck)
                }
            }
        })
    }
    
    /// 하단 가이드 텍스트
    private var guideText: some View {
        Text(CheckScanCameraConstants.guideText)
            .font(.semibold20)
            .foregroundStyle(Color.black01)
    }
}

#Preview {
    @Previewable @State var currentCount: Int = 5
    ChekScanCamera(currentCount: $currentCount)
}
