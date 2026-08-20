//
//  HoverSystem.swift
//  ARCore
//
//  Created by 임영택 on 7/24/25.
//

import RealityKit
import UIKit
import os.log

struct HoverSystem: System {
    // MARK: - Type Properties
    /// 대상 엔티티 쿼리
    private static let query = EntityQuery(where: .has(HoverComponent.self))
    
    /// 뒷면  엔티티 이름
    private static let planeEntityName = "PlaneBack"
    
    // MARK: - Properties
    private let logger = Logger.of("HoverSystem")
    
    init(scene: Scene) { }
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(
            matching: Self.query,
            updatingSystemWhen: .rendering
        ) {
            let isHovering = entity.components[HoverComponent.self]?.isHovering ?? false
            entity.components[ParticleEmitterComponent.self]?.isEmitting = isHovering
        }
    }
}
