//
//  ARCoreFontSystem.swift
//  ARCore
//
//  Created by 임영택 on 7/25/25.
//

import UIKit

/// ARCore 모듈에서 사용할 폰트 목록
enum ARCoreFont {
    case title
    case subtitle
}

/// 폰트 설정을 위한 구조체
public struct ARCoreFontSetting {
    let title: UIFont
    let subtitle: UIFont
    
    public init(title: UIFont, subtitle: UIFont) {
        self.title = title
        self.subtitle = subtitle
    }
}

/// 주입받은 폰트를 가지고 있는 클래스. 싱글톤 사용 강제.
class ARCoreFontSystem {
    static let shared = ARCoreFontSystem()
    
    private(set) var title: UIFont?
    private(set) var subtitle: UIFont?
    
    private init() { }
    
    /// 폰트 시스템을 설정한다. 각 타이포그라피에 따라 Font 객체를 지정한다.
    func configure(title: UIFont, subtitle: UIFont) {
        self.title = title
        self.subtitle = subtitle
    }
    
    /// 폰트 시스템을 설정한다. ARCoreFontSetting 구조체를 넘긴다.
    func configure(with setting: ARCoreFontSetting) {
        configure(title: setting.title, subtitle: setting.subtitle)
    }
    
    /// 특정 타이포그라피에 대한 폰트를 반환한다.
    func font(for style: ARCoreFont) -> UIFont {
        switch style {
        case .title: title ?? .systemFont(ofSize: 64, weight: .black)
        case .subtitle: subtitle ?? .systemFont(ofSize: 32, weight: .bold)
        }
    }
}

extension UIFont {
    static var arCoreTitle: UIFont {
        ARCoreFontSystem.shared.font(for: .title)
    }
    
    static var arCoreSubtitle: UIFont {
        ARCoreFontSystem.shared.font(for: .subtitle)
    }
}
