//
//  EnvironmentValues+Injection.swift
//  Config
//
//  Created by Apple MacBook on 7/18/25.
//

import Foundation
import SwiftUI

#if DEBUG
private struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DIContainer = .init()
}
#else
private struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DIContainer = {
        fatalError("의존성 주입 오류 발생!! 똑바로 주입하세욧!!")
    }()
}
#endif

public extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}
