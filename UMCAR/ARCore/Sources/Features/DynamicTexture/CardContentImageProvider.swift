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
    let allCards: [GameCard]
    
    /// 이미지 로드 후 캐시
    private let imageCache: CardContentImageCache?
    
    /// 현재 쓰기 중인 태스크를 보관
    private var writingTasks: [UUID: Task<UIImage?, Never>] = [:]
    
    private let logger = Logger.of("CardContentImageProvider")
    
    init(
        reader: CardContentImageReader,
        writer: CardContentImageWriter,
        allCards: [GameCard],
        imageCache: CardContentImageCache? = nil
    ) {
        self.reader = reader
        self.writer = writer
        self.allCards = allCards
        self.imageCache = imageCache
    }
    
    init(allCards: [GameCard], imageCache: CardContentImageCache? = nil) {
        let baseURL: URL = {
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            return documentsURL.appending(path: "textures")
        }()
        
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
    func loadImage(cardData: GameCard) async {
        if let _ = imageCache?.get(id: cardData.id) {
            // 이미 이미지가 로드된 경우 넘어간다
            logger.debug("image for \(cardData.wordEng) already loaded in cache")
            return
        }
        
        if let image = reader.getImage(cardId: cardData.id) {
            // 파일 시스템에 있는 경우 바로 캐시 웜엄
            logger.debug("image for \(cardData.wordEng) loaded from disk")
            imageCache?.set(image, id: cardData.id)
            return
        }
        
        if let _ = writingTasks[cardData.id] {
            // 쓰기 중인 태스크가 있는 경우 넘어간다
            logger.debug("image for \(cardData.wordEng) now writing")
            return
        }
        
        // 새로 태스크를 만들어야 하는 경우
        logger.debug("will begin to write image for \(cardData.wordEng)")
        let task = createWriteImageTask(for: cardData)
        writingTasks[cardData.id] = task
    }
    
    /// 특정 카드의 앞면 이미지를 반환한다
    func getImage(cardData: GameCard) async -> UIImage? {
        if let image = imageCache?.get(id: cardData.id) {
            // 이미 이미지가 로드된 경우
            logger.debug("image for \(cardData.wordEng) already loaded in cache")
            return image
        }
        
        if let image = reader.getImage(cardId: cardData.id) {
            // 파일 시스템에 있는 경우 바로 캐시 웜엄
            logger.debug("image for \(cardData.wordEng) loaded from disk")
            imageCache?.set(image, id: cardData.id)
            return image
        }
        
        if let task = writingTasks[cardData.id] {
            // 쓰기 중인 태스크가 있는 경우 넘어간다
            logger.debug("image for \(cardData.wordEng) now writing")
            return await task.value
        }
        
        // 새로 태스크를 만들어야 하는 경우
        logger.debug("will begin to write image for \(cardData.wordEng)")
        let task = createWriteImageTask(for: cardData)
        writingTasks[cardData.id] = task
        return await task.value
    }
    
    private func createWriteImageTask(for cardData: GameCard) -> Task<UIImage?, Never> {
        Task<UIImage?, Never> {
            defer {
                self.writingTasks.removeValue(forKey: cardData.id)
            }

            do {
                try writer.writeImage(cardData: cardData)
                logger.debug("\(cardData.wordEng) image written")

                if let image = reader.getImage(cardId: cardData.id) {
                    imageCache?.set(image, id: cardData.id)
                    return image
                } else {
                    logger.error("Image written but failed to read back: \(cardData.wordEng)")
                    return nil
                }
            } catch {
                logger.error("Failed to write image for \(cardData.wordEng): \(error.localizedDescription)")
                return nil
            }
        }
    }
}
