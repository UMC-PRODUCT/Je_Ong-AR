import SwiftUI
import SwiftData
import Dependency

@main
struct UMCARApp: App {
    @StateObject var container = DIContainer()

    /// 부스에서 플레이할 고정 레벨 (집 안 물건 / Easy). 다른 레벨로 바꾸려면 levels-*.json의 id로 교체한다.
    private static let fixedLevelID = UUID(uuidString: "7d01afc7-dff6-4e4f-92ac-247dce38b8ea")!

    private let modelContainer: ModelContainer = {
        do {
            let container = try ModelContainer(for: 
                                                CategoryModel.self,
                                               CardModel.self,
                                               LevelModel.self,
                                               GameSessionModel.self,
                                               UsedCardModel.self
            )
            
            if needBootstrapped() {
                let bootstrapper = DataBootstrapper(context: container.mainContext)
                try bootstrapper.bootstrap()
                setBootstrapSuccess(value: true)
            }

            return container
        } catch {
            setBootstrapSuccess(value: false)
            fatalError("SwiftData 컨테이너 초기화 실패: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ARView(levelModelID: Self.fixedLevelID)
                .id(container.gameSessionID)
                .environmentObject(container)
                .modelContainer(modelContainer)
        }
    }
}

extension UMCARApp {
    /// 부트스트랩이 필요한지 여부를 판단한다
    private static func needBootstrapped() -> Bool {
        let key = "hasBootstrapped"
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: key) {
            return false
        } else {
            return true
        }
    }
    
    /// 부트스트랩 필요 여부를 업데이트한다
    private static func setBootstrapSuccess(value: Bool) {
        let key = "hasBootstrapped"
        UserDefaults.standard.set(value, forKey: key)
    }
}
