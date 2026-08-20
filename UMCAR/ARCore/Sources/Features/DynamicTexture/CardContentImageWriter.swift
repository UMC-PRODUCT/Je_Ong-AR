//
//  CardContentImageWriter.swift
//  ARCore
//
//  Created by 임영택 on 7/28/25.
//

import Foundation
import UIKit
import os.log

/// AR 패널 텍스처용 팔레트.
///
/// ARCore 는 에셋 카탈로그가 없는 모듈이라 UMCAR 의 `Color.xcassets` 토큰을
/// 참조할 수 없다. Big-Dipper 디자인 시스템의 라이트 값을 그대로 박아둔다 —
/// 텍스처는 PNG 로 구워지므로 다크 모드 변형이 필요 없다.
private enum PanelPalette {
    /// indigo600 — 기술명
    static let title = UIColor(red: 0x3A / 255, green: 0x5A / 255, blue: 0xD9 / 255, alpha: 1)
    /// indigo200 — 구분선
    static let divider = UIColor(red: 0xCC / 255, green: 0xD6 / 255, blue: 0xFF / 255, alpha: 1)
    /// grey600 — 태그
    static let tag = UIColor(red: 0x6D / 255, green: 0x78 / 255, blue: 0x82 / 255, alpha: 1)
    /// grey800 — 설명 문단
    static let detail = UIColor(red: 0x34 / 255, green: 0x36 / 255, blue: 0x3E / 255, alpha: 1)
}

class CardContentImageWriter {
    /// 배경 색상
    let cardBackgroundColor: UIColor
    
    /// 이미지 너비
    let cardWidth: Double
    
    /// 이미지 높이
    let cardHeight: Double
    
    /// 너비와 높이 가지고 이미지 해상도를 계산할 떄 사용하는 인자
    let scaleFactor: Double
    
    /// 저장할 위치
    let baseURL: URL
    
    private let logger = Logger.of("CardContentImageWriter")
    
    init(
        baseURL: URL,
        cardBackgroundColor: UIColor = UIColor(white: 0.98, alpha: 1.0),
        // 패널은 카드와 같은 비율(90 x 127mm)이다. 가로 카드 앞면이 아니다.
        cardWidth: Double = 680,
        cardHeight: Double = 960,
        scaleFactor: Double = 4
    ) {
        self.baseURL = baseURL
        self.cardBackgroundColor = cardBackgroundColor
        self.cardWidth = cardWidth
        self.cardHeight = cardHeight
        self.scaleFactor = scaleFactor
        
        createBaseDirectoryIfNeeded()
    }
    
    /// 베이스 디렉토리가 없다면 만든다.
    private func createBaseDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: baseURL.path) {
            try? FileManager.default.createDirectory(
                at: baseURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
    
    /// 특정 게임 카드의 이미지를 쓴다.
    func writeImage(cardData: TechCard) throws {
        let imageData = imageFrom(
            card: cardData,
            size: .init(width: scale(cardWidth), height: scale(cardHeight))
        )
        
        let desinationURL = baseURL.appending(path: "\(cardData.id).png")
        try imageData.write(to: desinationURL)
    }
    
    /// 패널에 그릴 이미지를 만든다.
    ///
    /// 세로 구성 — 로고 / 기술명 / 태그 / 설명 문단. 치수는 PanelLayout이 쥔다.
    private func imageFrom(card: TechCard, size: CGSize) -> Data {
        let layout = PanelLayout(card: card, size: size)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.pngData { context in
            cardBackgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // 내용 블록의 총 높이를 먼저 재고 세로 중앙에 놓는다.
            // 설명 길이가 카드마다 달라서 위에서부터 쌓으면 짧은 카드는 아래가 크게 빈다.
            var y = max(size.height * PanelLayout.Ratio.topInset,
                        (size.height - layout.totalHeight) / 2)

            // 로고
            let logo = UIImage(named: card.logoAssetName)
                ?? UIImage(systemName: "app.dashed")!
            logo.draw(in: CGRect(x: (size.width - layout.logoSide) / 2, y: y,
                                 width: layout.logoSide, height: layout.logoSide))
            y += layout.logoSide + size.height * PanelLayout.Ratio.logoGap

            // 기술명
            NSAttributedString(string: card.name, attributes: [
                .font: layout.nameFont,
                .paragraphStyle: layout.centered,
                .foregroundColor: PanelPalette.title,
            ]).draw(in: CGRect(x: layout.margin, y: y,
                               width: layout.contentWidth,
                               height: layout.nameFont.lineHeight * 2.2))
            y += layout.nameFont.lineHeight * PanelLayout.Ratio.nameLead

            // 태그
            NSAttributedString(string: card.tag, attributes: [
                .font: layout.tagFont,
                .paragraphStyle: layout.centered,
                .foregroundColor: PanelPalette.tag,
            ]).draw(in: CGRect(x: layout.margin, y: y,
                               width: layout.contentWidth,
                               height: layout.tagFont.lineHeight * 1.6))
            y += layout.tagFont.lineHeight * PanelLayout.Ratio.tagLead

            // 구분선
            PanelPalette.divider.setFill()
            context.fill(CGRect(x: layout.margin, y: y,
                                width: layout.contentWidth,
                                height: max(1, size.height * 0.002)))
            y += size.height * PanelLayout.Ratio.ruleGap

            // 설명 문단
            NSAttributedString(string: card.detail, attributes: [
                .font: layout.detailFont,
                .paragraphStyle: layout.justified,
                .foregroundColor: PanelPalette.detail,
            ]).draw(in: CGRect(x: layout.margin, y: y,
                               width: layout.contentWidth,
                               height: layout.detailHeight + layout.detailFont.lineHeight))
        }
    }

    private func scale(_ scalar: Double) -> Double {
        scalar * scaleFactor
    }
}
