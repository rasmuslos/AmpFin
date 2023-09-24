//
//  OfflinePlay.swift
//  Music
//
//  Created by Rasmus Krämer on 24.09.23.
//

import Foundation
import SwiftData

@Model
class OfflinePlay {
    let trackId: String
    let positionSeconds: Double
    
    init(trackId: String, positionSeconds: Double) {
        self.trackId = trackId
        self.positionSeconds = positionSeconds
    }
}
