//
//  ExhibitSettings.swift
//  ARCore
//

import ARKit

/// 앱이 ARCore에 주입하는 전시 설정.
///
/// 레퍼런스 이미지를 앱이 로드해서 넘긴다. ARCore가 앱 번들의 에셋 카탈로그를 직접
/// 뒤지면 모듈 의존이 역전되기 때문이다 (DESIGN.md §4).
public struct ExhibitSettings {
    /// 부스에 배치하는 카드들
    public let cards: [TechCard]

    /// 카드 뒷면 레퍼런스 이미지. 앱이 AR Resource Group에서 로드해 넘긴다
    public let referenceImages: Set<ARReferenceImage>

    public init(cards: [TechCard],
                referenceImages: Set<ARReferenceImage>,
                fontSetting: ARCoreFontSetting) {
        self.cards = cards
        self.referenceImages = referenceImages

        ARCoreFontSystem.shared.configure(with: fontSetting)
    }

    /// 레퍼런스 이미지 이름으로 카드를 찾는다.
    ///
    /// 이름이 어긋나면 인식은 되는데 조회가 실패해 패널이 안 뜬다. 그래서 호출부는
    /// nil을 조용히 넘기지 않고 로그를 남긴다.
    public func card(forReferenceImageNamed name: String) -> TechCard? {
        cards.first { $0.id == name }
    }
}
