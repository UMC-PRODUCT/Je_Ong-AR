//
//  CardRotator.swift
//  ARCore
//
//  Created by 길지훈 on 7/24/25.
//

import RealityKit
import ARKit
import os.log

/// AR 카드를 뒤집는(회전) 기능
///
/// ## 주요 기능
/// - 양방향 카드 회전 (뒷면 ↔ 앞면)
/// - 완료된 카드 회전 방지
/// - 부드러운 회전 애니메이션 적용
///
/// ## 사용법
/// ```swift
/// let rotator = CardRotator(arView: myARView)
/// rotator.operate(context: CardRotator.Input(cardEntity: myCardEntity))
/// // 이미 뒤집힌 카드는 자동으로 무시되게!
/// ```
class CardRotator: ARFeatureProvider {
    
    weak var arView: ARView?
    let logger = Logger.of("CardRotator")
    
    init(arView: ARView) {
        self.arView = arView
        logger.info("CardRotator 초기화됨.")
    }
    
    func operate(context: Input) {
        let cardEntity = context.cardEntity
        
        // 완료된 카드는 회전하지 않음
        guard let cardComponent = cardEntity.components[CardComponent.self] else {
            logger.error("카드 컴포넌트가 아닙니다.")
            return
        }
        
        guard !cardComponent.isCompleted else {
            logger.info("이미 완료된 카드라서 회전하지 않습니다.")
            return
        }
        
        // 카드 회전 실행 (양방향)
        rotateCard(cardEntity)
    }
    
    private func rotateCard(_ cardEntity: Entity) {
        let currentRotation = cardEntity.transform.rotation
        let additionalRotation = simd_quatf(angle: .pi, axis: [0, 1, 0]) // Y축 180도
        let targetRotation = currentRotation * additionalRotation
        
        // 상태 업데이트
        cardEntity.components[CardComponent.self]?.isFlipped.toggle()
        
        // 애니메이션으로 실제 회전 실행
        var targetTransform = cardEntity.transform
        targetTransform.rotation = targetRotation
        
        cardEntity.move(
            to: targetTransform,
            relativeTo: cardEntity.parent,
            duration: 0.5,
            timingFunction: .easeInOut
        )
        
        logger.info("카드를 뒤집었습니다.")
    }
    
    struct Input {
        let cardEntity: Entity
    }
    
    typealias Output = Void
}
