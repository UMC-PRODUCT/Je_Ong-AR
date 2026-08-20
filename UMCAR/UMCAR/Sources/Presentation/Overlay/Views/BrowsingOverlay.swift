//
//  BrowsingOverlay.swift
//  UMCAR
//

import SwiftUI
import Dependency

/// 카드를 한 장 이상 찾은 뒤의 오버레이.
///
/// 최소 구성이다 — 인식 수와 종료 버튼뿐. 화면을 비워두는 것이 의도다.
/// 관람객이 봐야 하는 건 실물 카드와 그 위에 뜨는 패널이지 오버레이가 아니다.
struct BrowsingOverlay: View {
    @Bindable var arViewModel: ARViewModel
    @EnvironmentObject var container: DIContainer

    private enum Constants {
        static let totalCards = 9
        static let cornerRadius: CGFloat = 20
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 10
        static let dropShadowSize: CGFloat = 4
    }

    var body: some View {
        Color.clear
            // 이게 없으면 화면 전체를 덮은 Color가 탭을 삼켜 ARView가 못 받는다.
            // 카드 탭을 ARView가 직접 받는 구조라 배경은 히트 테스트에서 빠져야 한다.
            // 아래 overlay와 pauseButton은 이 뒤에 붙으므로 탭이 그대로 살아 있다.
            .allowsHitTesting(false)
            .overlay(alignment: .top) {
                detectedCountChip
            }
            .navigationBarBackButtonHidden(true)
            .safeAreaPadding(.trailing, UIConstants.naviLeadingPadding)
            .safeAreaPadding(.bottom, UIConstants.bottomPadding)
            .safeAreaPadding(.top, UIConstants.topPadding)
            .pauseButton()
    }

    private var detectedCountChip: some View {
        Text("\(arViewModel.detectedCardCount) / \(Constants.totalCards)")
            .font(.semibold20)
            .foregroundStyle(Color.black01)
            .monospacedDigit()
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.verticalPadding)
            .background(Material.ultraThin)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .grayShadow4()
    }
}

#Preview {
    BrowsingOverlay(arViewModel: .init())
        .environmentObject(DIContainer())
}
