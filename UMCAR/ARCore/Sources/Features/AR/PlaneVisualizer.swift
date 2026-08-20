//
//  PlaneVisualizer.swift
//  ARCore
//
//  Created by 임영택 on 7/19/25.
//

import ARKit
import RealityKit
import os.log

class PlaneVisualizer: ARFeatureProvider {
    weak var arView: ARView?
    
    let logger = Logger.of("PlaneVisualizer")
    
    /// 평면으로부터 띄울 오프셋
    let translationOffset: Float = 0.005
    
    init(arView: ARView) {
        self.arView = arView
    }
    
    /// ARPlaneAnchor를 시각화하는 RealityKit 엔티티를 ARView 씬에 추가하고 반환한다.
    /// - Parameter context: 인식한 ARPlaneAnchor와 애니메이트 여부
    /// - Returns: 추가한 AnchorEntity. 실패했으면 nil을 반환.
    func operate(context: Input) -> AnchorEntity? {
        guard let arView = arView else {
            return nil
        }
        
        let planeAnchor = context.planeAnchor
        
        // 평면에 고정될 AnchorEntity 생성
        let anchorEntity = AnchorEntity(anchor: planeAnchor)
        
        // 실제 스캔 크기에 더 가깝도록 95% 크기로 시각화
        let visualWidth = planeAnchor.planeExtent.width * 0.95  // 95% 크기
        let visualHeight = planeAnchor.planeExtent.height * 0.95
        let planeMesh = MeshResource.generatePlane(width: visualWidth, depth: visualHeight)
        
        logger.debug("📐 a plane appeared...! size: \(planeAnchor.planeExtent.width)x\(planeAnchor.planeExtent.height)")
        
        let material = SimpleMaterial(color: .systemBlue.withAlphaComponent(0.6), isMetallic: false)
        
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])
        
        // 더 높이 띄워서 겹치지 않게
        planeEntity.transform.translation.y = translationOffset
        
        // 초기 스케일
        planeEntity.transform.scale = context.animate ? [0.2, 0.2, 0.2] : [1.0, 1.0, 1.0]
        
        // 앵커에 평면 추가
        anchorEntity.addChild(planeEntity)
        
        // 씬에 추가
        arView.scene.addAnchor(anchorEntity)
        
        // 스케일을 키우는 애니메이션
        if context.animate {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                var transform = planeEntity.transform
                transform.scale = [1.0, 1.0, 1.0]
                
                planeEntity.move(
                    to: transform,
                    relativeTo: anchorEntity,
                    duration: 0.5,
                    timingFunction: .easeOut
                )
            }
        }
        
        return anchorEntity
    }
    
    struct Input {
        let planeAnchor: ARPlaneAnchor
        let animate: Bool
    }
}
