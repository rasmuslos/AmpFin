//
//  OfflineLyrics.swift
//  Music
//
//  Created by Rasmus Krämer on 20.10.23.
//

import Foundation
import SwiftData
import AFFoundation

@Model
final internal class OfflineLyricsV2 {
    @Attribute(.unique)
    let trackIdentifier: String
    let contents: Track.Lyrics
    
    init(trackIdentifier: String, contents: Track.Lyrics) {
        self.trackIdentifier = trackIdentifier
        self.contents = contents
    }
}

internal extension OfflineLyricsV2 {
    @Attribute(.unique)
    var id: String {
        trackIdentifier
    }
}

internal typealias OfflineLyrics = OfflineLyricsV2
