//
//  Item.swift
//  JellyfinMusic
//
//  Created by Rasmus Krämer on 05.09.23.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
