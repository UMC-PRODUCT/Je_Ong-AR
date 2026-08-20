//
//  DIContainer.swift
//  Config
//
//  Created by Apple MacBook on 7/18/25.
//

import Foundation

public final class DIContainer: ObservableObject {
    /// 현재 게임 세션 식별자. 값이 바뀌면 AR 화면이 새로 생성되어 게임이 처음부터 다시 시작된다.
    @Published public private(set) var gameSessionID: UUID = .init()

    public init() {}

    /// 게임을 처음부터 다시 시작한다
    public func restartGame() {
        gameSessionID = .init()
    }
}
