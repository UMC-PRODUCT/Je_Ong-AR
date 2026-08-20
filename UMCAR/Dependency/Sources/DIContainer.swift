//
//  DIContainer.swift
//  Config
//
//  Created by Apple MacBook on 7/18/25.
//

import Foundation

public final class DIContainer: ObservableObject {
    /// 현재 전시 세션 식별자. 값이 바뀌면 AR 화면이 새로 생성되어 처음부터 다시 시작된다.
    @Published public private(set) var sessionID: UUID = .init()

    public init() {}

    /// 전시를 처음부터 다시 시작한다
    public func restartSession() {
        sessionID = .init()
    }
}
