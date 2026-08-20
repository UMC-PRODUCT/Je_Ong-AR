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
/// RealityKit의 `generatePlane(width:depth:)`도 x-z 평면이라 회전 보정이 필요 없다.
/// 인쇄물의 위쪽은 -Z로 가고, 카드를 바로 읽는 관람객은 그 반대편인 +Z 쪽에 선다.
enum CardPanelBuilder {
    /// 패널이 카드보다 얼마나 큰가.
    ///
    /// 카드와 같은 크기면 책상 높이에서 본문이 안 읽힌다. 텍스처는 2720x3840이라
    /// 키워도 뭉개지지 않는다 — 병목은 해상도가 아니라 실물 크기였다.
    ///
    /// 1.8이면 실물 16.2 x 22.9cm, 대략 A4다. 여기에 PanelLayout의 본문 비율을
    /// 곱하면 글자가 약 9mm로 선다.
    static let panelScale: Float = 1.8

    /// 패널을 세우는 각도 (라디안).
    ///
    /// 카드와 나란히 눕히면 책상 위 카드를 위에서 내려다봐야 읽힌다. 독서대처럼
    /// 기울여 관람객 쪽을 보게 한다.
    static let panelTilt: Float = .pi / 4

    /// 세운 패널의 아래 모서리가 카드 평면 위로 떠 있어야 할 여유 (미터)
    static let panelClearance: Float = 0.02

    /// 무지개 테두리를 카드 표면에서 띄우는 높이 (미터).
    /// 0이면 카드 평면과 겹쳐 z-fighting으로 깜빡인다.
    static let highlightLift: Float = 0.002

    /// 테두리가 카드보다 얼마나 큰가. 실물 카드 가장자리를 감싸 보이게 한다.
    static let highlightScale: Float = 1.12

    /// 세운 패널의 중심을 카드 평면에서 얼마나 띄울지 구한다.
    ///
    /// 기울이면 가까운 쪽 모서리가 `panelDepth/2 * sin(tilt)` 만큼 내려간다.
    /// 그만큼 올려주지 않으면 모서리가 책상을 뚫고 들어가 잘려 보인다.
    static func panelLift(panelDepth: Float) -> Float {
        panelDepth / 2 * sin(panelTilt) + panelClearance
    }

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

        // 패널. 텍스처는 applyPanelTexture에서 물린다.
        var placeholder = UnlitMaterial(color: .white)
        placeholder.blending = .transparent(opacity: 0.92)
        let panelWidth = width * panelScale
        let panelDepth = depth * panelScale
        let panel = ModelEntity(
            mesh: .generatePlane(width: panelWidth, depth: panelDepth),
            materials: [placeholder]
        )
        panel.position = [0, panelLift(panelDepth: panelDepth), 0]
        // +X축 기준 양의 회전은 먼 쪽(-Z) 모서리를 들어올린다. 앞면 법선도
        // 같이 관람객 쪽(+Z)으로 눕는다. 반대로 기울면 이 각도의 부호만 뒤집으면 된다.
        panel.orientation = simd_quatf(angle: panelTilt, axis: [1, 0, 0])
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
