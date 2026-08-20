//
//  ARContainerViewController+Tap.swift
//  ARCore
//

import RealityKit
import UIKit

extension ARContainerViewController {
    /// arView에 탭 제스처를 붙인다. viewDidLoad에서 부른다.
    ///
    /// SwiftUI로 탭 좌표를 왕복시키지 않는다. 예전 구조는 trigger* Bool을 토글해
    /// AR에 명령을 밀어넣었는데, 좌표를 넘기는 데 그 왕복이 필요하지 않다.
    func setupTapGesture() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(recognizer)
    }

    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: arView)

        switch selection.tap(cardID(at: point)) {
        case let .opened(id):
            panelEntities[id]?.isEnabled = true
        case let .closed(id):
            panelEntities[id]?.isEnabled = false
        case let .replaced(from, to):
            panelEntities[from]?.isEnabled = false
            panelEntities[to]?.isEnabled = true
        case .unchanged:
            return
        }

        delegate?.didChangeSelection(self, cardID: selection.selected)
    }

    /// 탭 지점에 카드가 있으면 그 id를, 없으면 nil을 준다.
    ///
    /// 히트한 엔티티가 패널 같은 자식일 수 있으므로 조상을 거슬러 찾는다.
    private func cardID(at point: CGPoint) -> String? {
        guard let hit = arView.entity(at: point) else { return nil }

        var entity: Entity? = hit
        while let current = entity {
            if let component = current.components[TechCardComponent.self] {
                return component.cardID
            }
            entity = current.parent
        }
        return nil
    }
}
