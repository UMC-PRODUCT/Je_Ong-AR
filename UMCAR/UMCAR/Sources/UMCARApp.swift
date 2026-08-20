import SwiftUI
import Dependency

@main
struct UMCARApp: App {
    @StateObject var container = DIContainer()

    var body: some Scene {
        WindowGroup {
            ARView()
                .id(container.gameSessionID)
                .environmentObject(container)
        }
    }
}
