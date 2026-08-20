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
    let exhibitSettings: ExhibitSettings
    
    /// 현재 발생한 에러. 에러가 없으면 nil
    @Binding var exhibitPhase: ExhibitPhase
    
    /// 현재 발생한 에러. 에러가 없으면 nil
    @Binding var arError: Error?
    
    /// 스캔 시작 트리거
    @Binding var triggerScanStart: Bool
    
    public init(
        exhibitSettings: ExhibitSettings,
        exhibitPhase: Binding<ExhibitPhase>,
        arError: Binding<Error?>,
        triggerScanStart: Binding<Bool>
    ) {
        self.exhibitSettings = exhibitSettings
        self._exhibitPhase = exhibitPhase
        self._arError = arError
        self._triggerScanStart = triggerScanStart
    }
    
    public func makeUIViewController(context: Context) -> ARContainerViewController {
        let viewController = ARContainerViewController(exhibitSettings: exhibitSettings)
        viewController.delegate = context.coordinator
        return viewController
    }
    
    public func updateUIViewController(_ uiViewController: ARContainerViewController, context: Context) {
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
    
    public class Coordinator: ARContainerViewControllerDelegate {
        
        var parent: ARContainer
        
        init(_ parent : ARContainer) {
            self.parent = parent
        }
        
        
        
        public func didChangePhase(_ arContainer: ARContainerViewController) {
            DispatchQueue.main.async {
                self.parent.exhibitPhase = arContainer.exhibitPhase
            }
        }
        
        
    }
}
