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
        )
    ]
)
