//
//  ARContainerViewController+ARFeatures.swift
//  ARCore
//
//  Created by 임영택 on 7/19/25.
//

import ARKit
import RealityKit

/// ARView 초기화, 해제 로직
extension ARContainerViewController {
    // MARK: - Setup ARView
    
    /// 처음 ARView를 초기화한다
    func setupARView() {
        // 카드 앞면 이미지 웜업
        Task.detached {
            await self.cardContentImageProvider.loadAllImages()
        }
        
        // 시스템 등록
        DynamicCardContentSystem.imageProvider = cardContentImageProvider
        DynamicCardContentSystem.registerSystem()
        
        arView.session.delegate = self
        
        arView.environment.sceneUnderstanding.options = [
            .occlusion,
            .receivesLighting
        ]
        
        prepareFeatureProviders()
        
        resetSession()
        
        logger.info("✅ ARView have been setup")
    }
    
    func prepareFeatureProviders() {
        self.cardDetector = CardDetector(arView: arView)
        
        logger.info("✅ FeatureProviders 초기화 완료")
    }
    
    /// 현재 ARSession을 리셋한다
    public func resetSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical]
        
        if isDebugModeEnabled {
            arView.debugOptions = [
                .showAnchorGeometry,
                .showFeaturePoints,
                .showWorldOrigin,
                .showSceneUnderstanding
            ]
        }
        
        arView.session.run(configuration)
        
        logger.info("✅ ARSession have been started")
    }
    
    /// 카드 스캔을 시작한다.
    ///
    /// 세션은 setupARView에서 이미 돌고 있다. 여기서 하는 일은 페이즈를 넘기는 것뿐이다 —
    /// 예전 startDetectingPlane은 평면 감지를 켜는 일까지 했지만, 이미지 인식은
    /// 세션 설정에 detectionImages가 들어 있으면 처음부터 동작한다.
    public func startScanning() {
        guard exhibitPhase == .initialized else { return }
        exhibitPhase = .scanning
    }
    
    /// 현재 ARSession을 멈춘다
    public func pauseSession() {
        arView.session.pause()
    }
}

/// ARSessionDelegate 구현
extension ARContainerViewController: ARSessionDelegate {
    /// 앵커 처리는 Task 10의 +ImageDetection에서 붙는다
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        logger.debug("새 앵커 \(anchors.count)개")
    }
}
