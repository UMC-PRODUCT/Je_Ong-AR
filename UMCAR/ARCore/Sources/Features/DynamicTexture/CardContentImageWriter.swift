//
//  CardContentImageWriter.swift
//  ARCore
//
//  Created by 임영택 on 7/28/25.
//

import Foundation
import UIKit
import os.log

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
        cardBackgroundColor: UIColor = UIColor(
            red: 238 / 255,
            green: 238 / 255,
            blue: 199 / 255,
            alpha: 1.0
        ),
        cardWidth: Double = 680,
        cardHeight: Double = 440,
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
    func writeImage(cardData: GameCard) throws {
        let imageData = imageFrom(
            engTitle: cardData.wordEng,
            korTitle: cardData.wordKor,
            image: cardData.image,
            size: .init(width: scale(cardWidth), height: scale(cardHeight))
        )
        
        let desinationURL = baseURL.appending(path: "\(cardData.id).png")
        try imageData.write(to: desinationURL)
    }
    
    /// 특정 텍스트가 포함된 이미지를 생성한다
    private func imageFrom(
        engTitle: String,
        korTitle: String,
        image: UIImage,
        size: CGSize,
        textColor: UIColor = .black
    ) -> Data {
        let renderer = UIGraphicsImageRenderer(size: size)
        let pngData = renderer.pngData { context in
            // 배경 그리기
            cardBackgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // 이미지
            let imageRect = CGRect(
                origin: .init(x: scale(40), y: scale(80)),
                size: .init(width: scale(280), height: scale(280))
            )
            image.draw(in: imageRect)
            
            // 단락 스타일
            let paragraphStyle: NSMutableParagraphStyle = {
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                return style
            }()
            
            // 영문 텍스트
            let engTextRect = CGRect(
                origin: .init(x: scale(336), y: scale(116)),
                size: .init(width: scale(304), height: scale(80))
            )
            let engAttributedText = NSAttributedString(string: engTitle, attributes: [
                .font: UIFont.arCoreTitle.withSize(scale(UIFont.arCoreTitle.pointSize)),
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.black,
                .strokeColor: UIColor.white,
                .strokeWidth: -10,
            ])
            engAttributedText.draw(in: engTextRect)
            
            // 국문 텍스트
            let korTextRect = CGRect(
                origin: .init(x: scale(336), y: scale(280)),
                size: .init(width: scale(304), height: scale(47))
            )
            let korAttributedText = NSAttributedString(string: korTitle, attributes: [
                .font: UIFont.arCoreSubtitle.withSize(scale(UIFont.arCoreSubtitle.pointSize)),
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.black,
                .strokeColor: UIColor.white,
                .strokeWidth: -6,
            ])
            korAttributedText.draw(in: korTextRect)
        }
        
        return pngData
    }
    
    private func scale(_ scalar: Double) -> Double {
        scalar * scaleFactor
    }
}
