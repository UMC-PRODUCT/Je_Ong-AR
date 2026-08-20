//
//  Project.swift
//  Config
//
//  Created by Apple MacBook on 7/18/25.
//

import Foundation
import ProjectDescription

let project = Project(
    name: "ARCore",
    packages: [.local(path: "./Packages/KonglishARProject")],
    targets: [
        .target(name: "ARCore",
                destinations: .iOS,
                product: .staticFramework,
                bundleId: "app.arCore.UMCAR",
                deploymentTargets: .iOS("18.0"),
                infoPlist: .default,
                sources: ["Sources/**"],
                resources: ["Resources/**"],
                dependencies: [.package(product: "KonglishARProject")]
        ),
        // 전환 과정에서 만드는 순수 로직(CardSelection, TechCard 무결성)은
        // 시뮬레이터에서 검증 가능한 유일한 조각이다. 검증할 곳을 먼저 만든다.
        .target(name: "ARCoreTests",
                destinations: .iOS,
                product: .unitTests,
                bundleId: "app.arCoreTests.UMCAR",
                deploymentTargets: .iOS("18.0"),
                infoPlist: .default,
                sources: ["Tests/**"],
                resources: [],
                dependencies: [.target(name: "ARCore")]
        )
    ]
)
