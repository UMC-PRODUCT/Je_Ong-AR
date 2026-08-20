//
//  ExhibitViewController+ARFeatures.swift
//  ARCore
//
//  Created by 임영택 on 7/19/25.
//

import ARKit
import RealityKit

/// ARView 초기화, 해제 로직
extension ExhibitViewController {
    // MARK: - Setup ARView
    
    /// 처음 ARView를 초기화한다
    func setupARView() {
        // 카드 앞면 이미지 웜업
        Task.detached {
            await self.cardContentImageProvider.loadAllImages()
        }
        
        // 이걸 빠뜨리면 ARView가 세션을 제 마음대로 구성하면서 detectionImages가 덮인다
        arView.automaticallyConfigureSession = false
        arView.session.delegate = self
        
        arView.environment.sceneUnderstanding.options = [
            .occlusion,
            .receivesLighting
        ]
        
        // 카메라 프리뷰만 먼저 띄운다. 이미지 인식은 startScanning()에서 켠다.
        //
        // 인식을 여기서 켜면 시작 버튼을 누르기 전에 앵커가 도착한다. ARKit은
        // 레퍼런스 이미지마다 앵커를 "정확히 한 번" 붙이므로 그 앵커는 다시 오지
        // 않고, .scanning으로 넘어가도 전이시킬 앵커가 없어 .browsing에 못 간다.
        runPreviewSession()
        
        logger.info("✅ ARView have been setup")
    }
    
    /// 인식 없이 카메라 프리뷰만 돌린다. 시작 화면 배경용이다.
    private func runPreviewSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = []
        arView.session.run(configuration)
    }
    
    /// 이미지 인식을 켜고 세션을 리셋한다
    public func resetSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = exhibitSettings.referenceImages
        // 0 = 추적 안 함. 추적을 켜면 동시 4장 상한에 걸리는데, 카드는 책상에
        // 고정이라 추적이 필요 없다. 이때도 관측된 이미지마다 앵커가 붙는다
        // (Apple: "ARKit creates image anchors for observed reference images").
        configuration.maximumNumberOfTrackedImages = 0
        configuration.planeDetection = []
        // 실물 크기를 정확히 아는 상황에서 스케일 추정을 켜면 앵커가 흔들린다.
        configuration.automaticImageScaleEstimationEnabled = false
        
        if isDebugModeEnabled {
            arView.debugOptions = [
                .showAnchorGeometry,
                .showFeaturePoints,
                .showWorldOrigin,
                .showSceneUnderstanding
            ]
        }
        
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        logger.info("✅ ARSession have been started")
    }
    
    /// 카드 스캔을 시작한다.
    ///
    /// **페이즈를 먼저 올리고 세션을 돌린다.** 순서가 바뀌면 앵커가 .initialized
    /// 상태에서 도착해 browsing 전이를 놓친다 — ARKit은 레퍼런스 이미지마다 앵커를
    /// 정확히 한 번만 붙이므로 그 기회는 다시 오지 않는다.
    public func startScanning() {
        guard exhibitPhase == .initialized else { return }
        exhibitPhase = .scanning
        resetSession()
    }
    
    /// 현재 ARSession을 멈춘다
    public func pauseSession() {
        arView.session.pause()
    }
}

/// ARSessionDelegate 구현
extension ExhibitViewController: ARSessionDelegate {
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        handleAddedImageAnchors(anchors)
    }
}
