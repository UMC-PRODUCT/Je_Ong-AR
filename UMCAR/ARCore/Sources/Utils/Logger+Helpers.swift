//
//  Logger+Helpers.swift
//  ARCore
//
//  Created by 임영택 on 7/19/25.
//

import Foundation
import os.log

extension Logger {
    static let subsystem = Bundle.main.bundleIdentifier!
    
    /// 현재 번들의 bundleIdentifier를 subsystem으로 하는 로거를 생성한다
    static func of(_ category: String) -> Logger {
        Logger(subsystem: Logger.subsystem, category: category)
    }
}
