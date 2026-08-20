//
//  ARContainer.swift
//  ARCoreManifests
//
//  Created by 임영택 on 7/19/25.
//

import SwiftUI

/**
 ARContainerViewController를 SwiftUI로 브릿지하는 UIViewControllerRepresentable 클래스
 사용 방법은 ARCoreDemoApp 모듈 참고
 */
public struct ARContainer: UIViewControllerRepresentable {
    // MARK: - Properties
    let gameSettings: GameSettings
    
    /// 현재 발생한 에러. 에러가 없으면 nil
    @Binding var gamePhage: GamePhase
    
    /// 현재 발생한 에러. 에러가 없으면 nil
    @Binding var arError: Error?
    
    /// 현재 인식된 평면 수
    @Binding var currentDetectedPlanes: Int
    
    /// 스캔 시작 트리거
    @Binding var triggerScanStart: Bool
    
    /// 포털 생성 트리거
    @Binding var triggerCreatePortal: Bool
    
    /// 카드 배치 트리거
    @Binding var triggerPlaceCards: Bool
    
    public init(
        gameSettings: GameSettings,
        gamePhase: Binding<GamePhase>,
        arError: Binding<Error?>,
        currentDetectedPlanes: Binding<Int>,
        triggerScanStart: Binding<Bool>,
        triggerCreatePortal: Binding<Bool>,
        triggerPlaceCards: Binding<Bool>
    ) {
        self.gameSettings = gameSettings
        self._gamePhage = gamePhase
        self._arError = arError
        self._currentDetectedPlanes = currentDetectedPlanes
        self._triggerScanStart = triggerScanStart
        self._triggerCreatePortal = triggerCreatePortal
        self._triggerPlaceCards = triggerPlaceCards
    }
    
    public func makeUIViewController(context: Context) -> ARContainerViewController {
        let viewController = ARContainerViewController(gameSettings: gameSettings)
        viewController.delegate = context.coordinator
        return viewController
    }
    
    public func updateUIViewController(_ uiViewController: ARContainerViewController, context: Context) {
        if triggerScanStart {
            uiViewController.startDetectingPlane()
            
            DispatchQueue.main.async {
                triggerScanStart.toggle()
            }
        }
        
        if triggerCreatePortal {
            uiViewController.createPortalAtCenter()
            
            DispatchQueue.main.async {
                triggerCreatePortal.toggle()
            }
        }
        
        if triggerPlaceCards {
            uiViewController.placeCardsFromPortal()
            
            DispatchQueue.main.async {
                triggerPlaceCards.toggle()
            }
        }
        
                
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    public class Coordinator: ARContainerViewControllerDelegate {
        
        var parent: ARContainer
        
        init(_ parent : ARContainer) {
            self.parent = parent
        }
        
        public func arContainerDidFindPlaneAnchor(_ arContainer: ARContainerViewController) {
            parent.currentDetectedPlanes += 1
        }
        
        public func arContainerDidLosePlaneAnchor(_ arContainer: ARContainerViewController) {
            parent.currentDetectedPlanes -= 1
        }
        
        public func didChangeGamePhase(_ arContainer: ARContainerViewController) {
            DispatchQueue.main.async {
                self.parent.gamePhage = arContainer.gamePhase
            }
        }
        
        
    }
}
