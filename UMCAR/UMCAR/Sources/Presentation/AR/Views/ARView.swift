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

    /// 인트로 영상 게이트. `ExhibitPhase`에 끼워 넣지 않는다 — 인트로는 ARCore가
    /// 알 필요 없는 앱 레이어 관심사고, public enum을 건드릴 이유가 없다.
    ///
    /// `@State`라서 `restartSession()`이 `.id(container.sessionID)`로 이 뷰를 새로
    /// 만들 때 `.idle`로 돌아간다. 다음 관람객은 영상부터 다시 본다.
    private enum IntroStage {
        /// 아무도 없는 대기 상태. 시작 버튼을 눌러야 영상이 나간다.
        case idle
        /// 영상 재생 중. 스킵 불가.
        case playing
        /// 영상을 다 봤다. 이 뒤로는 기존 전시 흐름 그대로다.
        case done
    }
    @State private var introStage: IntroStage = .idle

    // MARK: - 무인 복귀
    /// 이만큼 아무 일도 없으면 관람객이 말없이 떠난 것으로 본다.
    /// 다음 사람이 남의 진행 상태를 이어받는 걸 막는 게 목적이다.
    private static let inactivityTimeout: Duration = .seconds(20)

    /// 무조작 타이머를 다시 재기 위한 토큰. 값이 바뀌면 `.task`가 취소되고
    /// 처음부터 잰다. Timer 를 직접 굴리고 invalidate 를 챙기는 것보다 짧다.
    @State private var activityToken = 0

    // MARK: - 전시 세팅을 위한 프로퍼티
    /// 패널 제목 폰트
    let titleFont: UIFont = UMCARFontFamily.Pretendard.semiBold.font(size: 64)
    /// 패널 본문 폰트
    let subtitleFont: UIFont = UMCARFontFamily.Pretendard.medium.font(size: 32)
    
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
        ExhibitContainer(
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
                switch introStage {
                case .idle:
                    IdleOverlay {
                        introStage = .playing
                    }
                case .playing:
                    IntroVideoView {
                        introStage = .done
                        // 확인 화면 없이 바로 스캔으로 넘긴다. 영상을 끝까지 본
                        // 관람객에게 "시작하시겠습니까"를 한 번 더 묻는 건 군더더기다.
                        arViewModel.startButtonTapped()
                    }
                case .done:
                    switch arViewModel.exhibitPhase {
                    case .initialized:
                        // 스캔 트리거가 ExhibitContainer 에 반영되기 전 한 프레임.
                        EmptyView()
                    case .scanning:
                        ScanGuideOverlay(arViewModel: arViewModel)
                            .environmentObject(container)
                    case .browsing:
                        BrowsingOverlay(arViewModel: arViewModel)
                            .environmentObject(container)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        // 관람객이 뭔가 하고 있다는 신호. 원시 탭을 잡지 않는 이유는 카드 탭이
        // ARView 안의 UIKit 제스처로 처리돼서 SwiftUI 쪽에서 새는 경우가 있어서다.
        // 이 네 가지가 바뀌었다면 사람이 있는 것이고, 안 바뀌었다면 없는 것이다.
        .onChange(of: introStage) { activityToken += 1 }
        .onChange(of: arViewModel.exhibitPhase) { activityToken += 1 }
        .onChange(of: arViewModel.detectedCardCount) { activityToken += 1 }
        .onChange(of: arViewModel.selectedCardID) { activityToken += 1 }
        .task(id: activityToken) {
            // 대기 화면은 아무도 없는 게 정상이다. 여기서는 영원히 기다린다.
            guard introStage != .idle else { return }

            try? await Task.sleep(for: Self.inactivityTimeout)
            guard !Task.isCancelled else { return }

            print("ℹ️ \(Self.inactivityTimeout) 동안 조작이 없어 대기 화면으로 돌아간다")
            container.restartSession()
        }
    }
}

