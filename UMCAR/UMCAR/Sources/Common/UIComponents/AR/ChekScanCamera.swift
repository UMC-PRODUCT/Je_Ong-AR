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
    /// 채워야 할 총 개수. 카드 장수가 바뀌면 호출부에서 넘긴다
    let maxCount: Int
    let guideText: String
    
    // MARK: - Constants
    fileprivate enum CheckScanCameraConstants {
        static let mainVspacing: CGFloat = 10
        static let listSpacing: CGFloat = 32
        static let horizonPadding: CGFloat = 63
        static let verticalPadding: CGFloat = 20
        static let cornerRadius: CGFloat = 20
        static let dropShadowSize: CGFloat = 4
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: CheckScanCameraConstants.mainVspacing, content: {
            checkList
            guideLabel
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
    private var guideLabel: some View {
        Text(guideText)
            .font(.semibold20)
            .foregroundStyle(Color.black01)
    }
}

#Preview {
    @Previewable @State var currentCount: Int = 5
    ChekScanCamera(currentCount: $currentCount, maxCount: 9,
                   guideText: "카드를 비추면 하나씩 채워집니다")
}
