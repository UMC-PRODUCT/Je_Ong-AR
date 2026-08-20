//
//  ARFeatureProvider.swift
//  ARCore
//
//  Created by 임영택 on 7/19/25.
//

import RealityKit

/// AR 기능을 제공하는 클래스의 공통 추상화 프로토콜
protocol ARFeatureProvider: AnyObject {
    /// 기능을 수행하는데 필요한 인풋 데이터 타입을 정의
    associatedtype Input
    associatedtype Output
    
    /// 기능을 반영할 ARView. weak으로 참조해야함.
    var arView: ARView? { get }
    
    /// 기능 수행 메서드
    func operate(context: Input) -> Output
}
