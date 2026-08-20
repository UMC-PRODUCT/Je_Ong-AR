//
//  TechCardComponent.swift
//  ARCore
//

import RealityKit

/// 엔티티가 어느 카드인지 표시한다.
///
/// 탭 히트 판정은 자식 엔티티를 맞힐 수 있으므로, 조상을 거슬러 이 컴포넌트를 찾는다.
public struct TechCardComponent: Component {
    public let cardID: String

    public init(cardID: String) {
        self.cardID = cardID
    }
}
