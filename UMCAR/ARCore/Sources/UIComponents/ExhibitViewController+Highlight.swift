//
//  ExhibitViewController+Highlight.swift
//  ARCore
//

import Combine
import Foundation
import RealityKit

/// 무지개 테두리를 매 프레임 흐르게 한다.
extension ExhibitViewController {
    /// 씬 업데이트를 구독해 테두리 애니메이션을 켠다. setupARView에서 한 번 부른다.
    ///
    /// ARSession의 didUpdate가 아니라 씬 이벤트에 붙는다. 앵커 갱신은 카드가
    /// 추적될 때만 오지만, 색은 카드가 하나도 안 잡힌 동안에도 계속 흘러야
    /// 다음 카드가 잡히는 순간 이미 살아 있는 상태로 나타난다.
    func startHighlightAnimation() {
        arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            self?.advanceHighlight(deltaTime: event.deltaTime)
        }
        .store(in: &sceneSubscriptions)
    }

    /// 흐른 시간만큼 색을 밀고, 보이는 테두리에만 새 머티리얼을 물린다.
    ///
    /// 머티리얼은 값 타입이라 엔티티마다 복사본을 갖는다. 한 번 만들어 돌려쓰되
    /// 대입은 카드 수만큼 해야 한다 — 동시에 추적되는 카드가 최대 4장이라
    /// (ExhibitViewController.maximumTrackedCards) 프레임당 네 번이면 끝난다.
    private func advanceHighlight(deltaTime: TimeInterval) {
        guard !highlightEntities.isEmpty else { return }
        highlightElapsed += deltaTime

        // 캐시된 텍스처를 꺼내는 것뿐이다. 첫 카드를 인식할 때 이미 구워졌다.
        guard let textures = CardHighlightTexture.make() else { return }
        let material = CardHighlightMaterial.make(textures: textures, elapsed: highlightElapsed)

        for entity in highlightEntities.values {
            // 부모(히트 판)가 꺼져 있으면 화면에 없는 테두리다. isEnabled는
            // 자식으로 전파되지만 자식 자신의 값은 그대로 true라, 부모를 봐야 한다.
            guard entity.parent?.isEnabled == true else { continue }
            entity.model?.materials = [material]
        }
    }
}
