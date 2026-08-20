//
//  ARContainerViewController.swift
//  ARCoreManifests
//
//  Created by 임영택 on 7/19/25.
//

import UIKit
import ARKit
import RealityKit
import os.log
import Combine

/// ARView를 포함하는 UIViewController
public class ARContainerViewController: UIViewController {
    // MARK: - Properties
    let arView = ARView()
    
    /// ARSession debugOption 포함 여부를 지정한다.  debugOption을 포함하고 싶으면 true로 지정한다. 세션을 다시 시작해야 반영된다.
    public var isDebugModeEnabled = false
    
    /// 대리자
    public weak var delegate: ARContainerViewControllerDelegate?
    
    /// 로거
    let logger = Logger.of("ARContainerViewController")
    
    /// 기능을 제공하는 클래스들
    var cardDetector: CardDetector?
    
    /// 씬에 대한 이벤트 구독을 보관
    var sceneSubscriptions: Set<AnyCancellable> = []
    
    // MARK: 게임 진행과 관련된 속성
    let gameSettings: GameSettings
    
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
    init(gameSettings: GameSettings) {
        self.gameSettings = gameSettings
        self.cardContentImageProvider = CardContentImageProvider(
            allCards: gameSettings.gameCards
        )
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupARView()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pauseSession()
    }
}

extension ARContainerViewController {
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
