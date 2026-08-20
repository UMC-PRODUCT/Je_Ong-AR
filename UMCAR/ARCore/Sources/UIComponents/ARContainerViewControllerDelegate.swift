//
//  ARContainerViewControllerDelegate.swift
//  ARCore
//
//  Created by 임영택 on 7/19/25.
//

/// ARContainerViewController의 작업을 위임받아 수행하는 대리자
public protocol ARContainerViewControllerDelegate: AnyObject {
    /// 전시 페이즈가 변경되었을 때 호출되는 메서드
    /// 현재 페이즈는 `exhibitPhase` 프로퍼티로 참조할 수 있다
    func didChangePhase(_ arContainer: ARContainerViewController)
    
    /// 새 카드를 인식했을 때 호출되는 메서드
    /// 인식된 총 개수는 `detectedCardCount` 프로퍼티로 참조할 수 있다
    func didDetectCard(_ arContainer: ARContainerViewController, cardID: String)
    
    /// 열린 패널이 바뀌었을 때 호출되는 메서드. nil이면 열린 패널이 없다
    func didChangeSelection(_ arContainer: ARContainerViewController, cardID: String?)
}
