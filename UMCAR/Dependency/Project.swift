//
//  Project.swift
//  Config
//
//  Created by Apple MacBook on 7/18/25.
//

import Foundation
import ProjectDescription

let project = Project(
    name: "Dependency",
    targets: [
        .target(name: "Dependency",
                destinations: .iOS,
                product: .staticFramework,
                bundleId: "app.dependency.UMCAR",
                deploymentTargets: .iOS("26.0"),
                infoPlist: .default,
                sources: ["Sources/**"],
                resources: ["Resources/**"],
                dependencies: []
        )
    ]
)
