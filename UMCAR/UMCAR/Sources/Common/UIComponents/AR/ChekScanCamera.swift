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
        /// 옛 check/emptyCheck PDF 의 자연 크기. SF Symbol 로 바꿔도 줄 폭이 그대로여야 한다.
        static let checkBoxSide: CGFloat = 42
        static let checkSymbolSize: CGFloat = 34
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
                checkBox(filled: index < currentCount)
            }
        })
    }
    
    /// 스캔 진행 칸 하나.
    ///
    /// 옛 초록 PDF 아이콘 대신 SF Symbol 을 쓴다 — 인디고 토큰으로 직접 틴트되고,
    /// 색을 바꾸려고 벡터 에셋을 다시 뽑을 일이 없다.
    private func checkBox(filled: Bool) -> some View {
        Image(systemName: filled ? "checkmark.square.fill" : "square")
            .font(.system(size: CheckScanCameraConstants.checkSymbolSize, weight: .medium))
            .foregroundStyle(filled ? Color.indigo500 : Color.grey300)
            .frame(width: CheckScanCameraConstants.checkBoxSide,
                   height: CheckScanCameraConstants.checkBoxSide)
    }

    /// 하단 가이드 텍스트
    private var guideLabel: some View {
        Text(guideText)
            .appFont(.title3, weight: .semibold, color: .grey900)
    }
}

#Preview {
    @Previewable @State var currentCount: Int = 5
    ChekScanCamera(currentCount: $currentCount, maxCount: 9,
                   guideText: "카드를 비추면 하나씩 채워집니다")
}
