import SwiftUI
import ARKit
import ARCore

public struct ContentView: View {
    @State var arError: Error?
    @State var detectedCardCount: Int = 0
    @State var triggerScanStart = false
    @State var exhibitPhase: ExhibitPhase = .initialized
    
    public init() {}
    
    public var body: some View {
        ZStack {
            ARContainer(
                exhibitSettings: ExhibitSettings(
                    cards: TechCard.all,
                    referenceImages: ARReferenceImage.referenceImages(
                        inGroupNamed: "TechCards", bundle: nil) ?? [],
                    fontSetting: ARCoreFontSetting(
                        title: .systemFont(ofSize: 64, weight: .black),
                        subtitle: .systemFont(ofSize: 32, weight: .bold)
                    )
                ),
                exhibitPhase: $exhibitPhase,
                arError: $arError,
                detectedCardCount: $detectedCardCount,
                triggerScanStart: $triggerScanStart
            )
            .ignoresSafeArea()
            
            VStack {
                Text("exhibitPhase: \(exhibitPhase)")
                
                Text("인식된 카드: \(detectedCardCount) / 9")
                
                Button("스캔 시작") {
                    triggerScanStart = true
                }
                .disabled(exhibitPhase != .initialized) // 스캔 시작 후 비활성화
                
                
                
                                                
                if let arError = arError {
                    Text("에러: \(arError.localizedDescription)")
                }
                
                Spacer()
            }
            
            VStack {
                Spacer()
                
                Text("+")
                    .font(.system(size: 32, weight: .bold))
                
                Spacer()
            }
        }
    }
    
    
}
