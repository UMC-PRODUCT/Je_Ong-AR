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
            dependencies: [.project(target: "ARCore", path: "../UMCAR/ARCore")],
            settings: .settings(
                base: [
                    // tuist generate 후에도 실기기 빌드가 되게 팀을 고정한다
                    "DEVELOPMENT_TEAM": "2Z52RL5Y3M",
                    "CODE_SIGN_STYLE": "Automatic"
                ]
            )
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
