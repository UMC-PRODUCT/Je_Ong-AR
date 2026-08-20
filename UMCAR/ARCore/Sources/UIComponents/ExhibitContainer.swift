//
//  ExhibitContainer.swift
//  ARCoreManifests
//
//  Created by 임영택 on 7/19/25.
//

import SwiftUI

/**
 ExhibitViewController를 SwiftUI로 브릿지하는 UIViewControllerRepresentable 클래스
 사용 방법은 ARCoreDemoApp 모듈 참고
 */
public struct ExhibitContainer: UIViewControllerRepresentable {
    // MARK: - Properties
    let exhibitSettings: ExhibitSettings
    
    /// 현재 발생한 에러. 에러가 없으면 nil
    @Binding var exhibitPhase: ExhibitPhase
    
    /// 현재 발생한 에러. 에러가 없으면 nil
    @Binding var arError: Error?
    
    /// 인식된 카드 수
    @Binding var detectedCardCount: Int
    
    /// 열린 패널의 카드 id. 없으면 nil
    @Binding var selectedCardID: String?
    
    /// 스캔 시작 트리거
    @Binding var triggerScanStart: Bool
    
    public init(
        exhibitSettings: ExhibitSettings,
        exhibitPhase: Binding<ExhibitPhase>,
        arError: Binding<Error?>,
        detectedCardCount: Binding<Int>,
        selectedCardID: Binding<String?>,
        triggerScanStart: Binding<Bool>
    ) {
        self.exhibitSettings = exhibitSettings
        self._exhibitPhase = exhibitPhase
        self._arError = arError
        self._detectedCardCount = detectedCardCount
        self._selectedCardID = selectedCardID
        self._triggerScanStart = triggerScanStart
    }
    
    public func makeUIViewController(context: Context) -> ExhibitViewController {
        let viewController = ExhibitViewController(exhibitSettings: exhibitSettings)
        viewController.delegate = context.coordinator
        return viewController
    }
    
    public func updateUIViewController(_ uiViewController: ExhibitViewController, context: Context) {
        if triggerScanStart {
            uiViewController.startScanning()
            
            DispatchQueue.main.async {
                triggerScanStart.toggle()
            }
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    public class Coordinator: ExhibitViewControllerDelegate {
        
        var parent: ExhibitContainer
        
        init(_ parent : ExhibitContainer) {
            self.parent = parent
        }
        
        
        
        public func didDetectCard(_ exhibitContainer: ExhibitViewController, cardID: String) {
            DispatchQueue.main.async {
                self.parent.detectedCardCount = exhibitContainer.detectedCardCount
            }
        }
        
        public func didChangeSelection(_ exhibitContainer: ExhibitViewController, cardID: String?) {
            DispatchQueue.main.async {
                self.parent.selectedCardID = cardID
            }
        }
        
        public func didChangePhase(_ exhibitContainer: ExhibitViewController) {
            DispatchQueue.main.async {
                self.parent.exhibitPhase = exhibitContainer.exhibitPhase
            }
        }
        
        
    }
}
