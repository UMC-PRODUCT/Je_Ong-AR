//
//  ARContainerViewController+ImageDetection.swift
//  ARCore
//

import ARKit
import RealityKit

extension ARContainerViewController {
    /// ARKit이 레퍼런스 이미지를 찾았을 때 호출된다.
    ///
    /// Apple 문서: "ARKit adds an image anchor to a session exactly once for each
    /// reference image." 그래도 이름이 카드와 안 맞는 경우는 로그를 남긴다 — 에셋
    /// 이름과 TechCard.id가 어긋나면 인식은 되는데 조회가 실패해 조용히 아무 일도
    /// 일어나지 않기 때문이다.
    func handleAddedImageAnchors(_ anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let imageAnchor = anchor as? ARImageAnchor else { continue }

            guard let name = imageAnchor.referenceImage.name else {
                logger.error("레퍼런스 이미지에 이름이 없다")
                continue
            }
            guard let card = exhibitSettings.card(forReferenceImageNamed: name) else {
                logger.error("등록되지 않은 카드다: \(name)")
                continue
            }
            guard cardEntities[card.id] == nil else { continue }

            let (hit, panel) = CardPanelBuilder.build(
                cardID: card.id,
                physicalSize: imageAnchor.referenceImage.physicalSize
            )

            let anchorEntity = AnchorEntity(anchor: imageAnchor)
            anchorEntity.addChild(hit)
            arView.scene.addAnchor(anchorEntity)

            cardEntities[card.id] = hit
            panelEntities[card.id] = panel

            if exhibitPhase == .scanning {
                exhibitPhase = .browsing
            }
            delegate?.didDetectCard(self, cardID: card.id)
            logger.info("카드 인식: \(card.id)")
        }
    }
}
