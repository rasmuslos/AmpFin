//
//  OfflineTrack.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData
import AFFoundation

@Model
final internal class OfflineTrackV2 {
    @Attribute(.unique)
    let id: String
    let name: String
    
    let released: Date?
    
    let album: Track.OfflineReducedAlbum
    let artists: [Item.OfflineReducedArtist]
    
    var favorite: Bool
    let runtime: Double
    
    var container: Container!
    var downloadId: Int?
    
    var lastPlayed: Date?
    
    init(id: String, name: String, released: Date?, album: Track.OfflineReducedAlbum, artists: [Item.OfflineReducedArtist], favorite: Bool, runtime: Double, downloadId: Int? = nil) {
        self.id = id
        self.name = name
        self.album = album
        self.released = released
        self.artists = artists
        self.favorite = favorite
        self.downloadId = downloadId
        self.runtime = runtime
        
        container = nil
    }
}

internal extension OfflineTrackV2 {
    enum Container: String, Codable {
        case aac = "aac"
        case m4a = "m4a"
        case mp3 = "mp3"
        case wav = "wav"
        case aiff = "aiff"
        case flac = "flac"
        case webma = "webma"
    }
}

internal typealias OfflineTrack = OfflineTrackV2
