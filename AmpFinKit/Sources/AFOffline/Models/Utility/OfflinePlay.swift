//
//  OfflinePlay.swift
//  Music
//
//  Created by Rasmus Krämer on 24.09.23.
//

import Foundation
import SwiftData

@Model
final internal class OfflinePlayV2 {
    let trackIdentifier: String
    let position: Double
    let date: Date
    
    public init(trackIdentifier: String, position: Double, date: Date) {
        self.trackIdentifier = trackIdentifier
        self.position = position
        self.date = date
    }
}

internal typealias OfflinePlay = OfflinePlayV2
