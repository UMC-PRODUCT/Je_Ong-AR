//
//  CardSelection.swift
//  ARCore
//

import Foundation

/// 카드 탭에 따른 선택 상태.
///
/// 패널은 한 번에 한 장만 뜬다. 관람객이 "지금 무엇을 보고 있는지" 헷갈리지 않게
/// 하려는 것이고, 덕분에 상태가 선택된 카드 id 하나로 끝난다.
///
/// ARKit·RealityKit 의존이 없다. 실기기 없이 검증 가능한 유일한 로직이라 일부러
/// 값 타입으로 떼어냈다.
public struct CardSelection: Equatable {
    /// 선택에 따라 무엇이 바뀌었는지. 호출부가 이걸 보고 패널 엔티티를 켜고 끈다.
    public enum Change: Equatable {
        case opened(String)
        case closed(String)
        case replaced(from: String, to: String)
        case unchanged
    }

    public private(set) var selected: String?

    public init() {}

    /// 선택을 강제로 놓는다.
    ///
    /// 탭이 아닌 이유로 닫아야 할 때 쓴다 — 열어둔 카드가 시야에서 사라지면
    /// 패널도 같이 사라지므로, 선택만 남겨두면 "열린 게 없는데 안내도 안 뜨는"
    /// 상태가 된다.
    @discardableResult
    public mutating func clear() -> Change {
        guard let previous = selected else { return .unchanged }
        selected = nil
        return .closed(previous)
    }

    /// 카드를 탭한다. `nil`은 빈 곳을 탭했다는 뜻이다.
    @discardableResult
    public mutating func tap(_ cardID: String?) -> Change {
        switch (selected, cardID) {
        case (nil, nil):
            return .unchanged

        case let (previous?, nil):
            selected = nil
            return .closed(previous)

        case let (nil, tapped?):
            selected = tapped
            return .opened(tapped)

        case let (previous?, tapped?) where previous == tapped:
            selected = nil
            return .closed(previous)

        case let (previous?, tapped?):
            selected = tapped
            return .replaced(from: previous, to: tapped)
        }
    }
}
