//
//  DataBootstrapper.swift
//  UMCAR
//
//  Created by 임영택 on 7/30/25.
//

import Foundation
import SwiftData
import os.log

struct DataBootstrapper {
    /// SwiftData 모델 컨텍스트. 주입이 필요하다
    private let context: ModelContext
    
    /// 카테고리 데이터셋 파일 이름
    private let categoriesFileName = "categories-20250817"
    
    /// 레벨 데이터셋 파일 이름
    private let levelsFileName = "levels-20250817"
    
    /// 카드 데이터셋 파일 이름
    private let cardsFileName = "cards-20250817"
    
    /// 데이터셋 확장자
    private let fileExt = "json"
    
    private let logger = Logger.init(subsystem: Bundle.main.bundleIdentifier ?? "app.umcar.UMCAR", category: "DataBootstrapper")
    
    public init(context: ModelContext) {
        self.context = context
    }
    
    /// 부트스트랩을 진행한다
    func bootstrap() throws {
        guard let categories = loadData(type: [ImportedCategory].self, fileName: categoriesFileName, ext: fileExt),
              let levels = loadData(type: [ImportedLevel].self, fileName: levelsFileName, ext: fileExt),
              let cards = loadData(type: [ImportedCard].self, fileName: cardsFileName, ext: fileExt) else {
            logger.error("failed to load category and card json files")
            return
        }
        
        logger.info("started to bootstrap data")
        
        categories.forEach { categoryDTO in
            let categoryModel = mapToCategoryModel(category: categoryDTO)
            context.insert(categoryModel)
        }
        
        levels.forEach { levelDTO in
            let levelModel = mapToLevelModel(level: levelDTO)
            context.insert(levelModel)
            
            let gameSessionModel = GameSessionModel(score: 0, level: levelModel)
            context.insert(gameSessionModel)
        }
        
        do {
            try context.save()
        } catch {
            logger.error("failed to save context after insert categories")
            throw error
        }
        
        cards.forEach { cardDTO in
            let model = mapToCardModel(card: cardDTO)
            context.insert(model)
        }
        
        do {
            try context.save()
        } catch {
            logger.error("failed to save context after insert cards")
            throw error
        }
        
        logger.info("bootstrap data completed!")
    }
    
    /// JSON 파일을 불러 배열로 반환한다
    private func loadData<T: Decodable>(type: T.Type, fileName: String, ext: String) -> T? {
        guard let fileLocation = Bundle.module.url(forResource: fileName, withExtension: ext) else { return nil }
        
        do {
            let data = try Data(contentsOf: fileLocation)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            logger.error("json file load error")
            return nil
        }
    }
    
    /// 카테고리 DTO 구조체를 SwiftData 모델로 매핑한다
    private func mapToCategoryModel(category: ImportedCategory) -> CategoryModel {
        guard let id = UUID(uuidString: category.id) else {
            logger.error("category id is invalid uuid...")
            fatalError()
        }
        
        return CategoryModel(
            id: id,
            imageName: category.imageName,
            nameKor: category.nameKor,
            nameEng: category.nameEng
        )
    }
    
    /// 레벨 DTO 구조체를 SwiftData 모델로 매핑한다
    private func mapToLevelModel(level: ImportedLevel) -> LevelModel {
        guard let id = UUID(uuidString: level.id) else {
            logger.error("level id is invalid uuid...")
            fatalError()
        }
        
        guard let categoryId = UUID(uuidString: level.categoryId) else {
            logger.error("category id is invalid uuid...")
            fatalError()
        }
        
        let categoryDescription = FetchDescriptor<CategoryModel>(predicate: #Predicate{
            $0.id == categoryId
        })
        
        do {
            let categoryModelFetchResult = try context.fetch(categoryDescription)
            guard let categoryModel = categoryModelFetchResult.first else {
                logger.error("fetch result is empty... id=\(categoryId)")
                fatalError()
            }
            
            guard let levelType = LevelType.from(numericValue: level.level) else {
                logger.error("level is empty... rawValue=\(level.level)")
                fatalError()
            }
            
            return LevelModel(id: id, levelNumber: levelType, category: categoryModel)
        } catch {
            logger.error("no categoryModel")
            fatalError()
        }
    }
    
    /// 카드 DTO 구조체를 SwiftData 모델로 매핑한다
    private func mapToCardModel(card: ImportedCard) -> CardModel {
        guard let id = UUID(uuidString: card.id) else {
            logger.error("card id is invalid uuid...")
            fatalError()
        }
        
        guard let levelId = UUID(uuidString: card.levelId) else {
            logger.error("category id is invalid uuid...")
            fatalError()
        }
        
        let levelDescription = FetchDescriptor<LevelModel>(predicate: #Predicate{
            $0.id == levelId
        })
        
        do {
            let levelModelFetchResult = try context.fetch(levelDescription)
            guard let levelModel = levelModelFetchResult.first else {
                logger.error("fetch result is empty... id=\(levelId)")
                fatalError()
            }
            
            return CardModel(
                id: id,
                imageName: card.imageName,
                pronunciation: card.pronunciation,
                wordKor: card.wordKor,
                wordEng: card.wordEng,
                level: levelModel
            )
        } catch {
            logger.error("no level model")
            fatalError()
        }
    }
}

fileprivate struct ImportedCategory: Decodable {
    let id: String
    let imageName: String
    let nameKor: String
    let nameEng: String
}

fileprivate struct ImportedLevel: Decodable {
    let id: String
    let categoryTitle: String
    let categoryId: String
    let level: Int
}

fileprivate struct ImportedCard: Decodable {
    let id: String
    let categoryTitle: String
    let levelId: String
    let wordLevel: Int
    let imageName: String
    let pronunciation: String
    let wordKor: String
    let wordEng: String
    let isBoss: Bool
}
