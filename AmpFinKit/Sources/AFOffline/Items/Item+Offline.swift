//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFBase

extension Item {
    public var offlineTracker: ItemOfflineTracker {
        ItemOfflineTracker(itemId: id, itemType: type)
    }
}
