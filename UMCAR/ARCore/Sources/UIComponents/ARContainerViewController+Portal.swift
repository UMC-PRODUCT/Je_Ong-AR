//
//  ARContainerViewController+Portal.swift
//  ARCore
//
//  Created by 길지훈 on 7/28/25.
//

import ARKit
import RealityKit

/// 포털 생성 및 관리 로직
extension ARContainerViewController {
    
    /// 화면 중앙을 기준으로 레이캐스트를 수행하여 수직 평면에 포털을 생성한다.
    public func createPortalAtCenter() {
        guard let portalVisualizer = self.portalVisualizer else {
            logger.error("CentralPortalVisualizer가 초기화되지 않았습니다.")
            return
        }
        
        // 화면 중앙에서 수직 평면을 대상으로 레이캐스트 수행
        let results = arView.raycast(from: arView.center, allowing: .estimatedPlane, alignment: .vertical)
        
        if let firstResult = results.first {
            // 레이캐스트 성공 후에만 gamePhase 변경
            self.gamePhase = .portalCreating
            // 현재 감지된 모든 평면의 위치를 저장 -> 다시 해당 위치로 카드를 배치하기 위함.
            for (planeAnchor, _) in detectedPlaneEntities {
                savedPlaneTransforms[planeAnchor.identifier] = planeAnchor.transform
            }
//            
//            // 평면 ARAnchor들을 ARSession에서 제거하여 ARKit의 자동 업데이트 중단
//            for (planeAnchor, _) in detectedPlaneEntities {
//                arView.session.remove(anchor: planeAnchor)
//            }
    
            let arAnchor = ARAnchor(transform: firstResult.worldTransform)
            arView.session.add(anchor: arAnchor)
            
            // CentralPortalVisualizer -> 포털 생성
            let portalAnchor = portalVisualizer.operate(context: .init(arAnchor: arAnchor))
            
            if portalAnchor != nil {
                
                // 평면들이 포털로 빨려 들어가는 애니메이션
                let animationDuration: TimeInterval = 3.0
                
                // 애니메이션 목표 지점: ARAnchor의 실제 월드 위치
                let animationTargetWorldPosition = arAnchor.transform.columns.3

                for (_, planeEntity) in detectedPlaneEntities {
                    
                    // planeEntity의 스케일, 위치 등 정보를 갖음
                    var targetTransform = planeEntity.transform
                    
                    // 목표 위치를 ARAnchor의 실제 월드 위치로 설정 -> 포털 위치!
                    targetTransform.translation = SIMD3<Float>(animationTargetWorldPosition.x, animationTargetWorldPosition.y, animationTargetWorldPosition.z)
                    
                    // 애니메이션의 끝에 스케일을 0으로 만들기
                    targetTransform.scale = .zero
                    
                    planeEntity.move(
                        to: targetTransform,
                        relativeTo: nil,
                        duration: animationDuration,
                        timingFunction: .easeOut
                    )
                }
                
                // 애니메이션 완료 후 평면 엔티티 제거 및 게임 페이즈 변경
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                    self.gamePhase = .portalCreated
                    self.removeDetectedPlaneEntities()
                }
                
            } else {
                // 포털 생성 실패 시 원래 상태로 복구
                self.gamePhase = .scanned
                logger.error("Hit-Test는 성공했으나 포털 생성에 실패했습니다.")
            }
            
        } else {
            logger.warning("❌ Hit-Test 실패: 화면 중앙에 수직 평면이 없습니다.")
            // TODO: 사용자에게 피드백을 주는 로직?
        }
    }
    
    /// 포털을 애니메이션과 함께 제거한다
    public func removePortalWithAnimation() {
        guard let portalAnchor = arView.scene.anchors.first(where: { $0.name == "PortalAnchor" }) else {
            logger.warning("제거할 포털을 찾을 수 없습니다")
            return
        }
        
        // 포털 모델 엔티티와 파티클 찾기
        portalAnchor.children.forEach { child in
            if let modelEntity = child as? ModelEntity {
                // 포털 원형이 중심에서 점점 작아지며 사라지는 애니메이션
                var disappearTransform = modelEntity.transform
                disappearTransform.scale = .zero
                
                modelEntity.move(
                    to: disappearTransform,
                    relativeTo: portalAnchor,
                    duration: 1.5,
                    timingFunction: .easeInOut
                )
            } else if child.components.has(ParticleEmitterComponent.self) {
                // 파티클도 함께 사라지게
                var particleTransform = child.transform
                particleTransform.scale = .zero
                
                child.move(
                    to: particleTransform,
                    relativeTo: portalAnchor,
                    duration: 1.5,
                    timingFunction: .easeInOut
                )
            }
        }
        
        // 애니메이션 완료 후 포털 완전 제거
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            portalAnchor.removeFromParent()
        }
    }
}
