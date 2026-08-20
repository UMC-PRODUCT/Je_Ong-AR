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
    
    func get(id: String) -> UIImage? {
        cache.object(forKey: getKey(id: id))
    }
    
    func set(_ image: UIImage, id: String) {
        cache.setObject(image, forKey: getKey(id: id))
    }
    
    private func getKey(id: String) -> NSString {
        NSString(string: id)
    }
}
