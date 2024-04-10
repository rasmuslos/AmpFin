//
//  OfflineLyrics.swift
//  Music
//
//  Created by Rasmus Krämer on 20.10.23.
//

import Foundation
import SwiftData
import AFBase

@Model
final class OfflineLyrics {
    let trackId: String
    let lyrics: Track.Lyrics
    
    init(trackId: String, lyrics: Track.Lyrics) {
        self.trackId = trackId
        self.lyrics = lyrics
    }
}
