//
//  CardContentImageProvider.swift
//  ARCore
//
//  Created by 임영택 on 7/28/25.
//

import Foundation
import UIKit
import os.log

actor CardContentImageProvider {
    let reader: CardContentImageReader
    let writer: CardContentImageWriter
    let allCards: [TechCard]
    
    /// 이미지 로드 후 캐시
    private let imageCache: CardContentImageCache?
    
    /// 현재 쓰기 중인 태스크를 보관
    private var writingTasks: [String: Task<UIImage?, Never>] = [:]
    
    private let logger = Logger.of("CardContentImageProvider")
    
    init(
        reader: CardContentImageReader,
        writer: CardContentImageWriter,
        allCards: [TechCard],
        imageCache: CardContentImageCache? = nil
    ) {
        self.reader = reader
        self.writer = writer
        self.allCards = allCards
        self.imageCache = imageCache
    }
    
    /// 구워둔 패널 PNG의 판본.
    ///
    /// **패널 생김새를 바꾸면 반드시 올려야 한다.** 굽는 비용을 아끼려고 결과를
    /// Documents에 남기는데, 프로바이더는 파일이 있으면 내용을 안 보고 그냥 읽는다.
    /// Documents는 앱 업데이트에도 살아남으므로, 판본이 없으면 레이아웃을 고쳐도
    /// 이미 설치된 아이패드에서는 **영원히 옛 패널이 뜬다** — 앱을 지우기 전까지.
    /// 실제로 태그 겹침을 고친 뒤에도 기기에서 그대로 보였다.
    ///
    /// 판본이 디렉토리 이름에 들어가므로, 올리는 순간 옛 PNG는 안 읽히고 새로 굽는다.
    ///
    /// - 1: 최초 (로고 / 기술명 / 태그 / 본문)
    /// - 2: 태그 제거, 기술명 높이를 실측
    public static let layoutVersion = 2

    /// 이번 판본의 텍스처가 사는 곳
    static func texturesURL() -> URL {
        let documentsURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appending(path: "textures-v\(layoutVersion)")
    }

    /// 지난 판본이 남긴 디렉토리를 지운다.
    ///
    /// 안 지우면 판본을 올릴 때마다 9장씩(장당 수 MB) 쌓인다. 실패해도 무시한다 —
    /// 청소를 못 했다고 전시를 멈출 이유는 없다.
    static func removeStaleTextures() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let current = texturesURL().lastPathComponent

        let contents = try? fileManager.contentsOfDirectory(
            at: documentsURL, includingPropertiesForKeys: nil
        )
        for url in contents ?? [] where url.lastPathComponent.hasPrefix("textures")
            && url.lastPathComponent != current {
            try? fileManager.removeItem(at: url)
        }
    }

    init(allCards: [TechCard], imageCache: CardContentImageCache? = nil) {
        Self.removeStaleTextures()
        let baseURL = Self.texturesURL()

        self.init(
            reader: CardContentImageReader(baseURL: baseURL),
            writer: CardContentImageWriter(baseURL: baseURL),
            allCards: allCards,
            imageCache: imageCache
        )
    }
    
    /// 모든 카드 이미지를 쓰고 캐시에 넣는다
    func loadAllImages() async {
        await withTaskGroup(of: Void.self) { group in
            for card in self.allCards {
                group.addTask {
                    await self.loadImage(cardData: card)
                }
            }
            
            await group.waitForAll()
            self.logger.info("loadAllImages() complete")
        }
    }
    
    /// 특정 카드의 앞면 이미지를 미리 로드해 캐시를 워업한다
    func loadImage(cardData: TechCard) async {
        if let _ = imageCache?.get(id: cardData.id) {
            // 이미 이미지가 로드된 경우 넘어간다
            logger.debug("image for \(cardData.name) already loaded in cache")
            return
        }
        
        if let image = reader.getImage(cardId: cardData.id) {
            // 파일 시스템에 있는 경우 바로 캐시 웜엄
            logger.debug("image for \(cardData.name) loaded from disk")
            imageCache?.set(image, id: cardData.id)
            return
        }
        
        if let _ = writingTasks[cardData.id] {
            // 쓰기 중인 태스크가 있는 경우 넘어간다
            logger.debug("image for \(cardData.name) now writing")
            return
        }
        
        // 새로 태스크를 만들어야 하는 경우
        logger.debug("will begin to write image for \(cardData.name)")
        let task = createWriteImageTask(for: cardData)
        writingTasks[cardData.id] = task
    }
    
    /// 특정 카드의 앞면 이미지를 반환한다
    func getImage(cardData: TechCard) async -> UIImage? {
        if let image = imageCache?.get(id: cardData.id) {
            // 이미 이미지가 로드된 경우
            logger.debug("image for \(cardData.name) already loaded in cache")
            return image
        }
        
        if let image = reader.getImage(cardId: cardData.id) {
            // 파일 시스템에 있는 경우 바로 캐시 웜엄
            logger.debug("image for \(cardData.name) loaded from disk")
            imageCache?.set(image, id: cardData.id)
            return image
        }
        
        if let task = writingTasks[cardData.id] {
            // 쓰기 중인 태스크가 있는 경우 넘어간다
            logger.debug("image for \(cardData.name) now writing")
            return await task.value
        }
        
        // 새로 태스크를 만들어야 하는 경우
        logger.debug("will begin to write image for \(cardData.name)")
        let task = createWriteImageTask(for: cardData)
        writingTasks[cardData.id] = task
        return await task.value
    }
    
    private func createWriteImageTask(for cardData: TechCard) -> Task<UIImage?, Never> {
        Task<UIImage?, Never> {
            defer {
                self.writingTasks.removeValue(forKey: cardData.id)
            }

            do {
                try writer.writeImage(cardData: cardData)
                logger.debug("\(cardData.name) image written")

                if let image = reader.getImage(cardId: cardData.id) {
                    imageCache?.set(image, id: cardData.id)
                    return image
                } else {
                    logger.error("Image written but failed to read back: \(cardData.name)")
                    return nil
                }
            } catch {
                logger.error("Failed to write image for \(cardData.name): \(error.localizedDescription)")
                return nil
            }
        }
    }
}
