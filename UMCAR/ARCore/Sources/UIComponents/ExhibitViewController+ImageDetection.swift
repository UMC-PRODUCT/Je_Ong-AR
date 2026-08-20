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

            // 추적 상한을 넘겨 붙은 앵커는 isTracked가 false다. 그대로 켜면
            // 추적도 안 되는 카드에 테두리가 붙는다.
            hit.isEnabled = imageAnchor.isTracked

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

    /// 추적 상태가 바뀐 카드를 켜고 끈다.
    ///
    /// **ARKit은 카드가 시야를 벗어나도 앵커를 지우지 않는다.** `isTracked`를 안 보면
    /// 관람객이 다른 곳을 비춰도 무지개 테두리가 허공에 그대로 남는다. 매 프레임
    /// 오지만 실제로 상태가 바뀔 때만 엔티티를 건드린다.
    ///
    /// 동시 4장 상한 때문에, 화면에 5장 이상 들어오면 나머지는 여기서 꺼진다.
    func handleUpdatedImageAnchors(_ anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let imageAnchor = anchor as? ARImageAnchor,
                  let name = imageAnchor.referenceImage.name,
                  let card = exhibitSettings.card(forReferenceImageNamed: name)
            else { continue }

            setCardVisible(imageAnchor.isTracked, cardID: card.id)
        }
    }

    /// 앵커가 사라진 카드를 숨긴다.
    ///
    /// 엔티티는 지우지 않는다. `detectedCardCount`가 "지금 보이는 수"가 아니라
    /// "여태 찾은 수"라서, 지우면 n/9 카운터가 뒤로 간다.
    func handleRemovedImageAnchors(_ anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let imageAnchor = anchor as? ARImageAnchor,
                  let name = imageAnchor.referenceImage.name,
                  let card = exhibitSettings.card(forReferenceImageNamed: name)
            else { continue }

            setCardVisible(false, cardID: card.id)
        }
    }

    /// 카드에 딸린 엔티티 전체를 켜고 끈다.
    ///
    /// 히트 판을 끄면 자식인 패널·테두리도 같이 꺼지고, `arView.entity(at:)`도
    /// 안 맞는다 — 안 보이는 카드를 탭하는 일이 없어진다.
    private func setCardVisible(_ visible: Bool, cardID: String) {
        guard let entity = cardEntities[cardID], entity.isEnabled != visible else { return }
        entity.isEnabled = visible

        guard !visible, selection.selected == cardID else { return }

        // 열어둔 카드가 사라졌다. 패널과 선택을 같이 놓아야 다음 관람객에게
        // "카드를 터치하세요" 안내가 다시 뜬다.
        panelEntities[cardID]?.isEnabled = false
        selection.clear()
        delegate?.didChangeSelection(self, cardID: selection.selected)
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
