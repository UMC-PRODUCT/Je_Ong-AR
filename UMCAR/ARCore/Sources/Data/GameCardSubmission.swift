//
//  GameCardSubmission.swift
//  ARCore
//
//  Created by 임영택 on 8/17/25.
//

import Foundation

/// 제출된 단어 카드의 채점 정보를 표현하는 객체
public struct GameCardSubmission: Equatable {
    public let cardId: UUID
    public let score: Float
    public let isPassed: Bool
}
