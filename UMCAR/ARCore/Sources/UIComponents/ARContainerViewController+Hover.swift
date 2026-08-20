//
//  ARContainerViewController+Hover.swift
//  ARCore
//
//  Created by 임영택 on 7/26/25.
//

import Foundation
import RealityKit

extension ARContainerViewController {
    /// 씬이 업데이트될 때 실행되어 호버링 여부를 업데이트한다
    func updateHoveringState(event: SceneEvents.Update) {
        let observeCycle = 0.5
        
        // 누적 시간 증가
        self.observeHoveringAccumulatedTime += event.deltaTime

        // 일정 주기(`observeCycle`)마다 수행
        guard self.observeHoveringAccumulatedTime > observeCycle else {
            return
        }
        self.observeHoveringAccumulatedTime = 0  // 리셋
        
        let entityQuery = EntityQuery(where: .has(HoverComponent.self))
        self.arView.scene.performQuery(entityQuery)
            .forEach { cardEntity in
                cardEntity.components[HoverComponent.self]?.isHovering = false
            }
        
        let center = CGPoint(x: self.arView.bounds.midX, y: self.arView.bounds.midY)
        let hits = self.arView.hitTest(center)

        for result in hits {
            result.entity.components[HoverComponent.self]?.isHovering = true
        }
    }
}
