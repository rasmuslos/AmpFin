//
//  OfflineFavorite.swift
//
//  Created by Rasmus Krämer on 19.11.23.
//

import Foundation
import SwiftData

@Model
final internal class OfflineFavoriteV2 {
    @Attribute(.unique)
    let itemIdentifier: String
    var value: Bool
    
    init(itemIdentifier: String, value: Bool) {
        self.itemIdentifier = itemIdentifier
        self.value = value
    }
}

internal extension OfflineFavoriteV2 {
    @Attribute(.unique)
    var id: String {
        itemIdentifier
    }
}

internal typealias OfflineFavorite = OfflineFavoriteV2
