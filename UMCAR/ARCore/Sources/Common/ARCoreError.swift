//
//  ARCoreError.swift
//  ARCore
//
//  Created by 임영택 on 7/22/25.
//

import Foundation

/// ARCore 모듈 공통으로 사용되는 에러들
public enum ARCoreError: Error {
    case insufficientPlanes
    case cardNotFound
}

extension ARCoreError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .insufficientPlanes:
            return "아직 카드를 배치하기에 충분한 평면을 인식하지 못했어요. 공간을 더 촬영해주세요."
        case .cardNotFound:
            return "해당 ID로 게임 카드를 찾지 못했습니다."
        }
    }
}
