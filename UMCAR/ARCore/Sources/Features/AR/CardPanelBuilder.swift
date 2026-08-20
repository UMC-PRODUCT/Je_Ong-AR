//
//  CardPanelBuilder.swift
//  ARCore
//

import RealityKit
import UIKit

/// 카드 앵커에 붙일 엔티티를 만든다.
///
/// **좌표계.** `ARImageAnchor`의 로컬 공간은 이미지가 x-z 평면에 눕고 +Y가 법선이다
/// (Apple 샘플 주석: "ARImageAnchor assumes the image is horizontal in its local space").
/// RealityKit의 `generatePlane(width:depth:)`도 x-z 평면이라 회전 보정이 필요 없고,
/// 패널을 띄울 때는 +Y로 민다.
enum CardPanelBuilder {
    /// 패널이 카드 위로 뜨는 높이 (미터)
    static let panelLift: Float = 0.05

    /// 무지개 테두리를 카드 표면에서 띄우는 높이 (미터).
    /// 0이면 카드 평면과 겹쳐 z-fighting으로 깜빡인다.
    static let highlightLift: Float = 0.002

    /// 테두리가 카드보다 얼마나 큰가. 실물 카드 가장자리를 감싸 보이게 한다.
    static let highlightScale: Float = 1.12

    /// 반환값의 hit은 앵커에 붙이고, panel은 탭에 따라 isEnabled를 토글한다.
    /// highlight는 인식된 카드를 감싸는 무지개 테두리다 — 항상 켜둔다.
    static func build(cardID: String, physicalSize: CGSize)
        -> (hit: ModelEntity, panel: ModelEntity, highlight: ModelEntity?) {
        let width = Float(physicalSize.width)
        let depth = Float(physicalSize.height)

        // 히트 판정용 판. 렌더는 하지 않고 탭만 받는다.
        var invisible = UnlitMaterial(color: .clear)
        invisible.blending = .transparent(opacity: 0.0)
        let hit = ModelEntity(
            mesh: .generatePlane(width: width, depth: depth),
            materials: [invisible]
        )
        hit.components.set(TechCardComponent(cardID: cardID))
        hit.generateCollisionShapes(recursive: false)

        // 패널. 텍스처는 Task 12에서 굽는다.
        var placeholder = UnlitMaterial(color: .white)
        placeholder.blending = .transparent(opacity: 0.92)
        let panel = ModelEntity(
            mesh: .generatePlane(width: width, depth: depth),
            materials: [placeholder]
        )
        panel.position = [0, panelLift, 0]      // +Y = 카드 법선
        panel.isEnabled = false                  // 탭 전까지 숨김

        hit.addChild(panel)

        let highlight = makeHighlight(width: width, depth: depth)
        if let highlight {
            hit.addChild(highlight)
        }

        return (hit, panel, highlight)
    }

    /// 카드를 감싸는 무지개 테두리. 텍스처를 못 만들면 nil을 주고 테두리 없이 간다.
    private static func makeHighlight(width: Float, depth: Float) -> ModelEntity? {
        guard let texture = CardHighlightTexture.make() else { return nil }

        var material = UnlitMaterial()
        material.color = .init(tint: .white, texture: .init(texture))
        // 텍스처의 알파를 그대로 쓴다. 안 그러면 테두리 안쪽이 흰 판으로 덮인다.
        material.blending = .transparent(opacity: .init(scale: 1.0, texture: .init(texture)))

        let entity = ModelEntity(
            mesh: .generatePlane(width: width * highlightScale,
                                 depth: depth * highlightScale),
            materials: [material]
        )
        entity.position = [0, highlightLift, 0]      // +Y = 카드 법선
        return entity
    }
}
