//
//  OfflinePlay.swift
//  Music
//
//  Created by Rasmus Krämer on 24.09.23.
//

import Foundation
import SwiftData

@Model
public class OfflinePlay {
    let trackId: String
    let positionSeconds: Double
    let time: Date
    
    public init(trackId: String, positionSeconds: Double, time: Date) {
        self.trackId = trackId
        self.positionSeconds = positionSeconds
        self.time = time
    }
}
