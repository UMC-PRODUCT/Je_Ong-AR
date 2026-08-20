//
//  DynamicContentSystem.swift
//  ARCore
//
//  Created by 임영택 on 7/26/25.
//

import Foundation
import RealityKit
import UIKit
import os.log

struct DynamicCardContentSystem: System {    
    // MARK: - Type Properties
    /// 대상 엔티티 쿼리
    private static let query = EntityQuery(where: .has(CardComponent.self))
    
    /// 앞면 엔티티 이름
    private static let planeEntityName = "PlaneFront"
    
    /// 카드 너비
    static let cardWidth: Double = 680
    
    /// 카드 높이
    static let cardHeight: Double = 440
    
    /// 너비와 높이 가지고 이미지 해상도를 계산할 떄 사용하는 인자
    static let scaleFactor: Double = 4
    
    static let cardBackgroundColor: UIColor = UIColor(red: 0.855, green: 0.855, blue: 0.571, alpha: 1.0)
    
    // MARK: - Properties
    
    /// 이미지 제공자
    static var imageProvider: CardContentImageProvider?
    
    /// 로거
    private let logger = Logger.of("DynamicCardContentSystem")
    
    init(scene: Scene) { }
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(
            matching: Self.query,
            updatingSystemWhen: .rendering
        ) {
            for child in entity.children {
                if child.name == Self.planeEntityName {
                    if let modelEntity = child.children.first as? ModelEntity,
                       let cardComponent = entity.components[CardComponent.self] { // Nested `Plane`
                        
                        if cardComponent.isFrontRendered {
                            continue
                        }
                        
                        entity.components[CardComponent.self]?.isFrontRendered = true
                        
                        Task {
                            if let material = await createContentMaterial(for: modelEntity, cardData: cardComponent.cardData) {
                                await MainActor.run {
                                    modelEntity.model?.materials = [material]
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func createContentMaterial(for entity: HasModel, cardData: GameCard) async -> Material? {
        // Load Cache
        guard let cachedImage = await Self.imageProvider?.getImage(cardData: cardData) else {
            logger.error("CardContentImageProvider is not set")
            return nil
        }
        
        var material: Material
        do {
            let baseMaterial = extractBaseMaterial(from: entity) as? PhysicallyBasedMaterial
            material = try await convertImageToMaterial(from: cachedImage, baseMaterial: baseMaterial)
        } catch {
            let logMessage = "❌ DynamicTextureSystem: failed to create text image material"
                + "=> fallback texture will be applied."
                + "error:"
            logger.error("\(logMessage) \(error)")
            material = SimpleMaterial(color: .blue, isMetallic: false)
        }
        
        logger.debug("created front material for \(entity.id)")
        
        return material
    }
    
    /// UIImage를 CGImage로 변환하고, RealityKit 텍스쳐로 반환한다.
    @MainActor
    private func convertImageToMaterial(from image: UIImage, baseMaterial: PhysicallyBasedMaterial?) async throws -> Material {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "CGImage 변환 실패"])
        }

        // FIXME: - 나중에 처리하기
        let texture = try await TextureResource(
            image: cgImage,
            withName: nil,
            options: .init(semantic: .normal, compression: .default)
        )
        // CAUTION: Deprecated되어 `'init(image:withName:options:)'`를 사용하라는 경고가 발생하지만 사용하면 BAD_ACCESS 예외가 발생
        
        var material = baseMaterial ?? PhysicallyBasedMaterial()
        material.baseColor = .init(texture: MaterialParameters.Texture(texture)) // 원래 카드 엔티티 텍스쳐를 추출해 baseColor만 변경
        return material
    }
    
    private func extractBaseMaterial(from entity: Entity) -> Material? {
        guard let baseMaterialComponent = entity.components[ModelComponent.self] else {
            return nil
        }
        
        return baseMaterialComponent.materials.first
    }
}
