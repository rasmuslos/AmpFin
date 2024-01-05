//
//  File.swift
//
//
//  Created by Rasmus Krämer on 05.01.24.
//

import Foundation
import AFBaseKit

struct PlaybackInfo {
    let type: PlaybackType
    let tracks: [Track]
    
    enum PlaybackType {
        case album
        case playlist
        case search
        case tracks
        case unknown
    }
}
