//
//  ExhibitViewController.swift
//  ARCoreManifests
//
//  Created by 임영택 on 7/19/25.
//

import UIKit
import ARKit
import RealityKit
import os.log
import Combine

/// ARView를 품고 이미지 인식·탭을 처리하는 UIViewController
public class ExhibitViewController: UIViewController {
    // MARK: - Properties
    let arView = ARView()
    
    /// ARSession debugOption 포함 여부를 지정한다.  debugOption을 포함하고 싶으면 true로 지정한다. 세션을 다시 시작해야 반영된다.
    public var isDebugModeEnabled = false
    
    /// 대리자
    public weak var delegate: ExhibitViewControllerDelegate?
    
    /// 로거
    let logger = Logger.of("ExhibitViewController")
    
    /// 씬에 대한 이벤트 구독을 보관
    var sceneSubscriptions: Set<AnyCancellable> = []
    
    /// 카드 id → 히트 판 엔티티
    var cardEntities: [String: ModelEntity] = [:]
    
    /// 카드 id → 패널 엔티티
    var panelEntities: [String: ModelEntity] = [:]
    
    /// 인식된 카드 수. SwiftUI가 n/9로 표시한다
    public var detectedCardCount: Int { cardEntities.count }
    
    /// 어느 카드의 패널이 열려 있는지. 규칙은 CardSelection에 있고 테스트로 검증된다
    var selection = CardSelection()
    
    // MARK: 전시 진행과 관련된 속성
    let exhibitSettings: ExhibitSettings
    
    /// 게임카드 앞면 텍스쳐 이미지를 로드하는 객체
    let cardContentImageProvider: CardContentImageProvider
    
    /// 현재 전시 진행 단계
    public internal(set) var exhibitPhase: ExhibitPhase = .initialized {
        didSet {
            logger.info("ExhibitPhase changed to \(String(describing: self.exhibitPhase))")
            delegate?.didChangePhase(self)
        }
    }
    
    // MARK: - Init
    init(exhibitSettings: ExhibitSettings) {
        self.exhibitSettings = exhibitSettings
        self.cardContentImageProvider = CardContentImageProvider(
            allCards: exhibitSettings.cards
        )
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        TechCardComponent.registerComponent()
        setupUI()
        setupARView()
        setupTapGesture()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pauseSession()
    }
}

extension ExhibitViewController {
    // MARK: - Setup UI
    private func setupUI() {
        view.addSubview(arView)
        
        arView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            arView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arView.topAnchor.constraint(equalTo: view.topAnchor),
            arView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            arView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}
