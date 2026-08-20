import SwiftUI
import ARCore

public struct ContentView: View {
    @State var arError: Error?
    @State var triggerScanStart = false
    @State var exhibitPhase: ExhibitPhase = .initialized
    
    let gameCards: [GameCard] = [
        .init(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            imageName: "apple",
            wordKor: "사과",
            wordEng: "apple",
            image: UIImage(systemName: "apple.logo")!,
            isBoss: true
        ),
        .init(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            imageName: "banana",
            wordKor: "바나나",
            wordEng: "banana",
            image: UIImage(systemName: "questionmark.app.fill")!,
            isBoss: false
        ),
        .init(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            imageName: "cherry",
            wordKor: "체리",
            wordEng: "cherry",
            image: UIImage(systemName: "heart.fill")!,
            isBoss: false
        ),
        .init(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            imageName: "grape",
            wordKor: "포도",
            wordEng: "grape",
            image: UIImage(systemName: "leaf.fill")!,
            isBoss: false
        ),
        .init(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            imageName: "lemon",
            wordKor: "레몬",
            wordEng: "lemon",
            image: UIImage(systemName: "sun.max.fill")!,
            isBoss: false
        ),
//        .init(
//            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
//            imageName: "melon",
//            wordKor: "멜론",
//            wordEng: "melon",
//            image: UIImage(systemName: "circle.grid.hex.fill")!,
//            isBoss: false
//        ),
//        .init(
//            id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
//            imageName: "orange",
//            wordKor: "오렌지",
//            wordEng: "orange",
//            image: UIImage(systemName: "circle.fill")!,
//            isBoss: false
//        ),
//        .init(
//            id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
//            imageName: "peach",
//            wordKor: "복숭아",
//            wordEng: "peach",
//            image: UIImage(systemName: "cloud.sun.fill")!,
//            isBoss: false
//        ),
//        .init(
//            id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
//            imageName: "pineapple",
//            wordKor: "파인애플",
//            wordEng: "pineapple",
//            image: UIImage(systemName: "bolt.fill")!,
//            isBoss: false
//        ),
//        .init(
//            id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
//            imageName: "watermelon",
//            wordKor: "수박",
//            wordEng: "watermelon",
//            image: UIImage(systemName: "drop.fill")!,
//            isBoss: true
//        ),
    ]
    
    public init() {}
    
    public var body: some View {
        ZStack {
            ARContainer(
                gameSettings: GameSettings(
                    gameCards: gameCards,
                    fontSetting: ARCoreFontSetting(
                        title: .systemFont(ofSize: 64, weight: .black),
                        subtitle: .systemFont(ofSize: 32, weight: .bold)
                    )
                ),
                exhibitPhase: $exhibitPhase,
                arError: $arError,
                triggerScanStart: $triggerScanStart
            )
            .ignoresSafeArea()
            
            VStack {
                Text("exhibitPhase: \(exhibitPhase)")
                
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
