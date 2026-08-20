//
//  ARContainerViewControllerDelegate.swift
//  ARCore
//
//  Created by 임영택 on 7/19/25.
//

/// ARContainerViewController의 작업을 위임받아 수행하는 대리자
public protocol ARContainerViewControllerDelegate: AnyObject {
    /// 새로운 평면 앵커를 찾았을 때 호출되는 메서드
    func arContainerDidFindPlaneAnchor(_ arContainer: ARContainerViewController)
    
    /// 평면이 제거되어 포털이 부족해진 경우에 호출되는 메서드
    func arContainerDidLosePlaneAnchor(_ arContainer: ARContainerViewController)
    
    /// 게임 페이즈가 변경되었을 때 호출되는 메서드
    /// 게임의 페이즈는 `gamePhase` 프로퍼티로 참조할 수 있다
    func didChangeGamePhase(_ arContainer: ARContainerViewController)
}
