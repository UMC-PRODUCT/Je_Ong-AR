import ProjectDescription

let project = Project(
    name: "ARCoreDemoApp",
    targets: [
        .target(
            name: "ARCoreDemoApp",
            destinations: .iOS,
            product: .app,
            bundleId: "app.arCoreDemoApp.UMCAR",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "NSCameraUsageDescription": "AR 기능을 위해 카메라가 필요합니다."
                ]
            ),
            sources: ["ARCoreDemoApp/Sources/**"],
            resources: ["ARCoreDemoApp/Resources/**"],
            dependencies: [.project(target: "ARCore", path: "../UMCAR/ARCore")]
        ),
        .target(
            name: "ARCoreDemoAppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "app.arCoreDemoAppTests.UMCAR",
            infoPlist: .default,
            sources: ["ARCoreDemoApp/Tests/**"],
            resources: [],
            dependencies: [.target(name: "ARCoreDemoApp")]
        ),
    ]
)
