import SwiftUI

@main
struct ARCoreDemoAppApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                List {
                    NavigationLink("이미지 인식 검증") {
                        ImageDetectionProbeView()
                    }
                    NavigationLink("기존 데모 (평면·포탈)") {
                        ContentView()
                    }
                }
                .navigationTitle("ARCore Demo")
            }
        }
    }
}
