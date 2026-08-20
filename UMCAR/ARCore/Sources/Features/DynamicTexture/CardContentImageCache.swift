//
//  CardContentImageCache.swift
//  ARCore
//
//  Created by 임영택 on 7/28/25.
//

import Foundation
import RealityKit
import UIKit

class CardContentImageCache {
    private let cache = NSCache<NSString, UIImage>()
    
    func get(id: UUID) -> UIImage? {
        cache.object(forKey: getKey(id: id))
    }
    
    func set(_ image: UIImage, id: UUID) {
        cache.setObject(image, forKey: getKey(id: id))
    }
    
    private func getKey(id: UUID) -> NSString {
        NSString(string: id.uuidString)
    }
}
