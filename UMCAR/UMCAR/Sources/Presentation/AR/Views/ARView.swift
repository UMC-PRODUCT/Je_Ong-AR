//
//  ARView.swift
//  UMCAR
//
//  Created by 임영택 on 7/29/25.
//

import SwiftUI
import ARKit
import ARCore
import Dependency

struct ARView: View {
    @EnvironmentObject var container: DIContainer
    
    // MARK: - View Model
    @State var arViewModel: ARViewModel = .init()
    
    // MARK: - 게임 세팅을 위한 프로퍼티
    /// 앞면 이미지 타이틀 폰트
    let titleFont: UIFont = UMCARFontFamily.NPSFont.extraBold.font(size: 64)
    /// 앞면 이미지 서브타이틀 폰트
    let subtitleFont: UIFont = UMCARFontFamily.NPSFont.extraBold.font(size: 32)
    
    /// AR Resource Group에서 카드 뒷면 레퍼런스 이미지를 읽는다.
    ///
    /// 비어 있으면 인식이 통째로 죽는다. 조용히 넘기지 않고 로그를 남긴다 —
    /// 부스에서 "왜 아무것도 안 잡히지"의 원인이 여기일 가능성이 가장 높다.
    private var referenceImages: Set<ARReferenceImage> {
        guard let images = ARReferenceImage.referenceImages(
            inGroupNamed: Self.resourceGroupName, bundle: nil
        ) else {
            print("⚠️ AR Resource Group '\(Self.resourceGroupName)'을 찾지 못했다")
            return []
        }
        return images
    }

    private static let resourceGroupName = "TechCards"

    var body: some View {
        ARContainer(
            exhibitSettings: .init(
                cards: TechCard.all,
                referenceImages: referenceImages,
                fontSetting: .init(
                    title: titleFont,
                    subtitle: subtitleFont
                )
            ),
            exhibitPhase: $arViewModel.exhibitPhase,
            arError: $arViewModel.arError,
            detectedCardCount: $arViewModel.detectedCardCount,
            selectedCardID: $arViewModel.selectedCardID,
            triggerScanStart: $arViewModel.triggerScanStart
        )
        .overlay {
            Group {
                switch arViewModel.exhibitPhase {
                case .initialized:
                    StartOverlay(arViewModel: arViewModel)
                case .scanning:
                    CheckScanOverlay(arViewModel: arViewModel)
                case .browsing:
                    PlayingGameOverlay(arViewModel: arViewModel)
                        .environmentObject(container)
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
    }
}

