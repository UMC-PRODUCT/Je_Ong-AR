//
//  ExhibitPhase.swift
//  ARCore
//

import Foundation

/// 전시물의 진행 단계.
///
/// `scanning → browsing`은 단방향이다. 9장 중 몇 장을 찾았는지는 phase가 아니라
/// 별도 카운트로 노출한다 — 3장만 인식된 상태에서도 나머지를 계속 찾을 수 있어야
/// 하기 때문이다. 되돌아가는 전이가 없어서 예전 handleRemovedAnchors의 phase 가드
/// 버그가 구조적으로 재발하지 않는다 (DESIGN.md §3).
public enum ExhibitPhase {
    /// AR이 초기화만 되고 세션이 시작되지 않은 단계
    case initialized

    /// 세션이 돌고 있고 아직 카드를 하나도 못 찾은 단계
    case scanning

    /// 카드를 한 장 이상 찾아 열람 가능한 단계
    case browsing
}
