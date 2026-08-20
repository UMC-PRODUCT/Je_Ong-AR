//
//  ARContainer.swift
//  ARCoreManifests
//
//  Created by 임영택 on 7/19/25.
//

import SwiftUI

/**
 ARContainerViewController를 SwiftUI로 브릿지하는 UIViewControllerRepresentable 클래스
 사용 방법은 ARCoreDemoApp 모듈 참고
 */
public struct ARContainer: UIViewControllerRepresentable {
    // MARK: - Properties
    let gameSettings: GameSettings
    
    /// 현재 발생한 에러. 에러가 없으면 nil
    @Binding var gamePhage: GamePhase
    
    /// 현재 발생한 에러. 에러가 없으면 nil
    @Binding var arError: Error?
    
    /// 현재 인식된 평면 수
    @Binding var currentDetectedPlanes: Int
    
    /// 현재 라이프 카운트 수
    @Binding var currentLifeCounts: Int
    
    /// 현재 게임 스코어
    @Binding var currentGameScore: Int
    
    /// 해결한 카드 수
    @Binding var numberOfFinishedCards: Int
    
    /// 스캔 시작 트리거
    @Binding var triggerScanStart: Bool
    
    /// 포털 생성 트리거
    @Binding var triggerCreatePortal: Bool
    
    /// 카드 배치 트리거
    @Binding var triggerPlaceCards: Bool
    
    /// 카드 뒤집기 트리거
    @Binding var triggerFlipCard: Bool
    
    /// 뒤집힌 카드 UUID
    @Binding var flippedCardId: UUID?
    
    /// 제출된 카드 UUID에 대한 제출 정보
    @Binding var cardSubmissions: [UUID: GameCardSubmission]
    
    /// 단어의 아이디와 정확도
    /// 세팅하면 ARContainer에서 점수를 계산해 반영한다
    @Binding var triggerSubmitAccuracy: (UUID, Float)?
    
    public init(
        gameSettings: GameSettings,
        gamePhase: Binding<GamePhase>,
        arError: Binding<Error?>,
        currentDetectedPlanes: Binding<Int>,
        currentLifeCounts: Binding<Int>,
        currentGameScore: Binding<Int>,
        numberOfFinishedCards: Binding<Int>,
        flippedCardId: Binding<UUID?>,
        cardSubmissions: Binding<[UUID: GameCardSubmission]>,
        triggerScanStart: Binding<Bool>,
        triggerCreatePortal: Binding<Bool>,
        triggerPlaceCards: Binding<Bool>,
        triggerSubmitAccuracy: Binding<(UUID, Float)?>,
        triggerFlipCard: Binding<Bool>
    ) {
        self.gameSettings = gameSettings
        self._gamePhage = gamePhase
        self._arError = arError
        self._currentDetectedPlanes = currentDetectedPlanes
        self._currentLifeCounts = currentLifeCounts
        self._currentGameScore = currentGameScore
        self._numberOfFinishedCards = numberOfFinishedCards
        self._flippedCardId = flippedCardId
        self._cardSubmissions = cardSubmissions
        self._triggerScanStart = triggerScanStart
        self._triggerCreatePortal = triggerCreatePortal
        self._triggerPlaceCards = triggerPlaceCards
        self._triggerSubmitAccuracy = triggerSubmitAccuracy
        self._triggerFlipCard = triggerFlipCard
    }
    
    public func makeUIViewController(context: Context) -> ARContainerViewController {
        let viewController = ARContainerViewController(gameSettings: gameSettings)
        viewController.delegate = context.coordinator
        return viewController
    }
    
    public func updateUIViewController(_ uiViewController: ARContainerViewController, context: Context) {
        if triggerScanStart {
            uiViewController.startDetectingPlane()
            
            DispatchQueue.main.async {
                triggerScanStart.toggle()
            }
        }
        
        if triggerCreatePortal {
            uiViewController.createPortalAtCenter()
            
            DispatchQueue.main.async {
                triggerCreatePortal.toggle()
            }
        }
        
        if triggerPlaceCards {
            uiViewController.placeCardsFromPortal()
            
            DispatchQueue.main.async {
                triggerPlaceCards.toggle()
            }
        }
        
        if let triggerSubmitAccuracy = triggerSubmitAccuracy {
            let (wordId, accuracy) = triggerSubmitAccuracy
            
            var raisedError: Error?
            do {
                try uiViewController.submitAccuracy(wordId: wordId, accuracy: accuracy)
            } catch {
                // 메인 큐에서 비동기로 에러 바인딩 업데이트
                raisedError = error
            }
            
            DispatchQueue.main.async {
                self.triggerSubmitAccuracy = nil
                arError = raisedError
            }
        }
        
        if triggerFlipCard {
            let cardId = uiViewController.flipCardAtCenter()
            
            DispatchQueue.main.async {
                triggerFlipCard.toggle()
                flippedCardId = cardId
            }
        }
        
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    public class Coordinator: ARContainerViewControllerDelegate {
        
        var parent: ARContainer
        
        init(_ parent : ARContainer) {
            self.parent = parent
        }
        
        public func arContainerDidFindPlaneAnchor(_ arContainer: ARContainerViewController) {
            parent.currentDetectedPlanes += 1
        }
        
        public func arContainerDidLosePlaneAnchor(_ arContainer: ARContainerViewController) {
            parent.currentDetectedPlanes -= 1
        }
        
        public func didChangeGamePhase(_ arContainer: ARContainerViewController) {
            DispatchQueue.main.async {
                self.parent.gamePhage = arContainer.gamePhase
            }
        }
        
        public func didChangeLifeCount(_ arContainer: ARContainerViewController) {
            DispatchQueue.main.async {
                self.parent.currentLifeCounts = arContainer.reaminLifeCounts
            }
        }
        
        public func didChangeScore(_ arContainer: ARContainerViewController) {
            DispatchQueue.main.async {
                self.parent.currentGameScore = arContainer.currentScore
                self.parent.numberOfFinishedCards = arContainer.numberOfFinishedCards
                arContainer.gameCardToAccuracy
                    .compactMapValues({ $0 })
                    .forEach { key, value in
                        self.parent.cardSubmissions[key.id] = GameCardSubmission(
                            cardId: key.id,
                            score: value,
                            isPassed: arContainer.isPassed(accuracy: value)
                        )
                    }
            }
        }
    }
}
