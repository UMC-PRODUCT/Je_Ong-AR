//
//  ExhibitViewController+ImageDetection.swift
//  ARCore
//

import ARKit
import RealityKit

extension ExhibitViewController {
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

            let (hit, panel, _) = CardPanelBuilder.build(
                cardID: card.id,
                physicalSize: imageAnchor.referenceImage.physicalSize
            )

            let anchorEntity = AnchorEntity(anchor: imageAnchor)
            anchorEntity.addChild(hit)
            arView.scene.addAnchor(anchorEntity)

            cardEntities[card.id] = hit
            panelEntities[card.id] = panel
            applyPanelTexture(to: panel, card: card)

            if exhibitPhase == .scanning {
                exhibitPhase = .browsing
            }
            delegate?.didDetectCard(self, cardID: card.id)
            logger.info("카드 인식: \(card.id)")
        }
    }

    /// 구워둔 패널 이미지를 머티리얼로 물린다.
    ///
    /// 세션 시작 때 loadAllImages()로 전량 웜업하므로 보통 캐시에서 즉시 온다.
    /// 아직 안 구워졌으면 provider가 여기서 굽고 기다린다 — 그동안 패널은
    /// 흰 placeholder로 남는다.
    ///
    /// UnlitMaterial을 쓰는 이유: 부스 조명이 어두워도 글씨가 어둡게 깔리지 않는다.
    private func applyPanelTexture(to panel: ModelEntity, card: TechCard) {
        Task { [weak self] in
            guard let self,
                  let image = await self.cardContentImageProvider.getImage(cardData: card),
                  let cgImage = image.cgImage else {
                self?.logger.error("패널 이미지를 못 만들었다: \(card.id)")
                return
            }

            do {
                let texture = try await TextureResource(
                    image: cgImage,
                    options: .init(semantic: .color)
                )
                await MainActor.run {
                    var material = UnlitMaterial()
                    material.color = .init(texture: .init(texture))
                    panel.model?.materials = [material]
                }
            } catch {
                self.logger.error("텍스처 생성 실패 \(card.id): \(error.localizedDescription)")
            }
        }
    }
}
