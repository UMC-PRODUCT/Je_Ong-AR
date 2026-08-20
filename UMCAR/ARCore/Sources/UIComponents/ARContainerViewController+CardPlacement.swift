//
//  ARContainerViewController+CardPlacement.swift
//  ARCore
//
//  Created by 임영택 on 7/21/25.
//

import Foundation
import RealityKit

extension ARContainerViewController {
    /// 인식된 평면에 카드를 배치한다.
    /// 인식된 평면 수가 충분하지 않으면 `ARCoreError.insufficientPlanes` 예외를 던진다.
    public func placeCards() throws {
        let detectedPlaneAnchors = detectedPlaneEntities.keys
        let detectedPlaneVisualizations = detectedPlaneEntities.values
        
        // 인식된 평면 수가 충분한지 검사한다
        guard detectedPlaneAnchors.count >= gameSettings.gameCards.count else {
            logger.error("❌ insufficient planes. current number of planes: \(detectedPlaneAnchors.count) required: \(self.gameSettings.gameCards.count)")
            throw ARCoreError.insufficientPlanes
        }
        
        gamePhase = .scanned
        
        // 인식된 평면 엥커에 카드를 배치한다
        detectedPlaneAnchors.enumerated().forEach { (index, planeAnchor) in
            cardPositioner?.operate(context: .init(
                planeAnchor: planeAnchor,
                cardData: gameSettings.gameCards[index]
            ))
        }
        
        // 기존 평면 시각화 엔티티를 제거한다
        detectedPlaneVisualizations.forEach { anchorEntity in
            anchorEntity.children.removeAll()
            anchorEntity.removeFromParent()
        }
    }
    
    /// 포털에서 저장된 평면 위치로 카드들을 배치한다
    public func placeCardsFromPortal() {
        guard gamePhase == .portalCreated else {
            return
        }
        
        guard !savedPlaneTransforms.isEmpty else {
            logger.warning("저장된 평면 위치가 없습니다")
            return
        }
        
        guard let cardPositioner = self.cardPositioner else {
            logger.error("CardPositioner가 초기화되지 않았습니다.")
            return
        }
        
        // 포털 위치 찾기 (이름으로 정확하게 식별)
        guard let portalAnchor = arView.scene.anchors.first(where: { $0.name == "PortalAnchor" }) else {
            logger.error("포털 앵커를 찾을 수 없습니다")
            return
        }
        
        // 카드 배치 시작 즉시 상태 변경하여 다중 클릭 방지
        gamePhase = .cardPlacing
        
        let portalWorldPosition = portalAnchor.position(relativeTo: nil)
        
        // GameCard들과 저장된 위치들을 매칭
        let gameCards = Array(gameSettings.gameCards.prefix(savedPlaneTransforms.count))
        let savedTransformValues = Array(savedPlaneTransforms.values)
        
        for (index, gameCard) in gameCards.enumerated() {
            guard index < savedTransformValues.count else { break }
            
            let savedTransform = savedTransformValues[index]
            let delay = Float(index) * 0.3
            
            createAndAnimateCardFromPortal(
                gameCard: gameCard,
                portalPosition: portalWorldPosition,
                targetTransform: savedTransform,
                delay: delay,
                cardPositioner: cardPositioner
            )
        }
        
        // 모든 카드 애니메이션이 완료되면 포털 제거 및 게임 시작
        let totalAnimationTime = Float(gameCards.count) * 0.3 + 2.5
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(totalAnimationTime)) {
            self.removePortalWithAnimation()
            self.gamePhase = .playing
        }
    }
    
    /// 개별 카드를 포털에서 목표 위치로 애니메이션하며 배치
    private func createAndAnimateCardFromPortal(
        gameCard: GameCard,
        portalPosition: SIMD3<Float>,
        targetTransform: simd_float4x4,
        delay: Float,
        cardPositioner: CardPositioner
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(delay)) {
            // CardPositioner로 카드 생성 (원점에서 생성)
            guard let cardAnchorEntity = cardPositioner.createCardWithTransform(
                context: .init(transform: matrix_identity_float4x4, cardData: gameCard)
            ) else {
                return
            }
            
            // 먼저 씬에 추가
            self.arView.scene.addAnchor(cardAnchorEntity)
            
            // 초기 위치를 포털 위치로 설정
            var initialTransform = Transform(matrix: targetTransform)
            initialTransform.translation = portalPosition + SIMD3<Float>(0, 0, -0.2)
            cardAnchorEntity.transform = initialTransform
            
            // 목표 위치로 애니메이션
            var finalTransform = cardAnchorEntity.transform
            finalTransform.translation = SIMD3<Float>(
                targetTransform.columns.3.x,
                targetTransform.columns.3.y,  
                targetTransform.columns.3.z
            )
            finalTransform.rotation = simd_quatf(targetTransform)
            
            cardAnchorEntity.move(
                to: finalTransform,
                relativeTo: nil,
                duration: 2.5,
                timingFunction: .easeInOut
            )
        }
    }
}
