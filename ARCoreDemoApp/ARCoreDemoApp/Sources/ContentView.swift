import SwiftUI
import ARCore

public struct ContentView: View {
    @State var arError: Error?
    @State var currentDetectedPlanes: Int = 0
    @State var currentLifeCounts: Int = 5
    @State var currentGameScore: Int = 0
    @State var numberOfFinishedCards: Int = 0
    @State var triggerScanStart = false
    @State var triggerCreatePortal = false
    @State var triggerPlaceCards = false
    @State var triggerSubmitAccuracy: (UUID, Float)?
    @State var gamePhase: GamePhase = .initialized
    @State var triggerFlipCard = false
    @State var flippedCardId: UUID?
    // ARContainer가 요구하는 바인딩. 이게 없어 데모 타깃이 컴파일되지 않는 상태였다.
    @State var cardSubmissions: [UUID: GameCardSubmission] = [:]
    
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
                    minimumSizeOfPlane: 0.5,
                    fontSetting: ARCoreFontSetting(
                        title: .systemFont(ofSize: 64, weight: .black),
                        subtitle: .systemFont(ofSize: 32, weight: .bold)
                    )
                ),
                gamePhase: $gamePhase,
                arError: $arError,
                currentDetectedPlanes: $currentDetectedPlanes,
                currentLifeCounts: $currentLifeCounts,
                currentGameScore: $currentGameScore,
                numberOfFinishedCards: $numberOfFinishedCards,
                flippedCardId: $flippedCardId,
                cardSubmissions: $cardSubmissions,
                triggerScanStart: $triggerScanStart,
                triggerCreatePortal: $triggerCreatePortal,
                triggerPlaceCards: $triggerPlaceCards,
                triggerSubmitAccuracy: $triggerSubmitAccuracy,
                triggerFlipCard: $triggerFlipCard
            )
            .ignoresSafeArea()
            
            VStack {
                Text("gamePhase: \(gamePhase)")
                
                Text("currentDetectedPlanes: \(currentDetectedPlanes)")
                
                Text("currentLifeCounts: \(currentLifeCounts)")
                
                Text("currentGameScore: \(currentGameScore)")
                
                Text("numberOfPassedCards: \(numberOfFinishedCards)")
                
                Button("스캔 시작") {
                    triggerScanStart = true
                }
                .disabled(gamePhase == .scanning || gamePhase == .portalCreated) // 스캔 시작 후 비활성화
                
                Button {
                    if gamePhase == .scanned {
                        triggerCreatePortal = true
                    } else if gamePhase == .portalCreated {
                        triggerPlaceCards = true
                    }
                } label: {
                    Text(buttonText)
                }
                .disabled(buttonDisabled)
                
                Button("단어 정답 제출 1") {
                    if let id = gameCards.first?.id {
                        triggerSubmitAccuracy = (
                            id,
                            0.6
                        )
                    }
                }
                
                Button("단어 정답 제출 2") {
                    if gameCards.count >= 2 {
                        triggerSubmitAccuracy = (
                            gameCards[1].id,
                            0.3
                        )
                    }
                }
                
                Button("카드 뒤집기") {
                    triggerFlipCard = true
                }
                
                if let flippedCardId = flippedCardId {
                    Text("뒤집힌 카드: \(flippedCardId)")
                }
                
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
    
    var buttonText: String {
        switch gamePhase {
        case .scanned:
            return "포털 생성!"
        case .portalCreated:
            return "저 너머의 세계엔..?"
        default:
            return "..." // 다른 게임 단계에서는 버튼 텍스트를 다르게 설정하거나 숨길 수 있습니다.
        }
    }
    
    var buttonDisabled: Bool {
        switch gamePhase {
        case .scanned, .portalCreated:
            return false
        default:
            return true
        }
    }
}
