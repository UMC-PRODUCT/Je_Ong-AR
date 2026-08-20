//
//  CardContentImageReader.swift
//  ARCore
//
//  Created by 임영택 on 7/28/25.
//

import Foundation

import Foundation
import UIKit
import os.log

class CardContentImageReader {
    /// 이미지를 읽을 베이스 디렉토리
    let baseURL: URL
    
    private let logger = Logger.of("CardContentImageReader")
    
    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    /// 특정 아이디의 카드 이미지를 디스크에서 읽어 반환한다.
    func getImage(cardId: UUID) -> UIImage? {
        let imagePath = baseURL.appendingPathComponent("\(cardId).png")
        do {
            let imageData = try Data(contentsOf: imagePath)
            return UIImage(data: imageData)
        } catch {
            logger.error("error during reading image file: \(error)")
            return nil
        }
    }
}
