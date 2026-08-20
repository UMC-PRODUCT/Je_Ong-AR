import ProjectDescription

// 버전 정보
let marketingVersion = "1.0.0"
let currentProjectVersion = "1"

let project = Project(
    name: "UMCAR",
    packages: [
        .remote(url: "https://github.com/Moya/Moya", requirement: .upToNextMinor(from: "15.0.3"))
    ],
    targets: [
        .target(
            name: "UMCAR",
            destinations: [.iPad],
            product: .app,
            bundleId: "app.umcar.UMCAR",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "유엠카",
                    "CFBundleShortVersionString": .string(marketingVersion),
                    "CFBundleVersion": .string(currentProjectVersion),
                    "LSApplicationCategoryType": "public.app-category.education",         
                    "UIRequiredDeviceCapabilities": ["arkit"],
                    "UIRequiresFullScreen": true,
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "NSCameraUsageDescription": "AR을 위해 카메라 사용이 필요합니다",
                    "UIViewControllerBasedStatusBarAppearance": false,
                    "UIStatusBarHidden": true,
                    "UISupportedInterfaceOrientations~ipad": [
                        "UIInterfaceOrientationLandscapeLeft",
                        "UIInterfaceOrientationLandscapeRight"
                    ]
                ]
            ),
            sources: ["UMCAR/Sources/**"],
            resources: ["UMCAR/Resources/**"],
            dependencies: [
                .project(target: "Dependency", path: "./Dependency"),
                .project(target: "ARCore", path: "./ARCore"),
                .package(product: "Moya")
            ],
            settings: .settings(
                base: [
                    "MARKETING_VERSION": .string(marketingVersion),
                    "CURRENT_PROJECT_VERSION": .string(currentProjectVersion),
                    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
                    // 여기 없으면 tuist generate 할 때마다 서명 설정이 날아가
                    // 실기기 빌드가 "requires a development team"으로 깨진다.
                    "DEVELOPMENT_TEAM": "2Z52RL5Y3M",
                    "CODE_SIGN_STYLE": "Automatic"
                ]
            )
        ),
        .target(
            name: "UMCARTests",
            destinations: [.iPad],
            product: .unitTests,
            bundleId: "dev.tuist.UMCARTests",
            infoPlist: .default,
            sources: ["UMCAR/Tests/**"],
            resources: [],
            dependencies: [.target(name: "UMCAR")]
        ),
    ]
)
