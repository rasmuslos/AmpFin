//
//  OfflineFavorite.swift
//
//  Created by Rasmus Krämer on 19.11.23.
//

import Foundation
import SwiftData

@Model
class OfflineFavorite {
    let itemId: String
    let favorite: Bool
    
    init(itemId: String, favorite: Bool) {
        self.itemId = itemId
        self.favorite = favorite
    }
}
