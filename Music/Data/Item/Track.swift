//
//  Track.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

class Track: Item {
    let album: ReducedAlbum
    let artists: [ReducedArtist]
    
    let lufs: Float?
    let index: Index
    let playCount: Int
    let releaseDate: Date?
    
    init(id: String, name: String, sortName: String?, cover: Cover? = nil, favorite: Bool, album: ReducedAlbum, artists: [ReducedArtist], lufs: Float?, index: Index, playCount: Int, releaseDate: Date?) {
        self.album = album
        self.artists = artists
        self.lufs = lufs
        self.index = index
        self.playCount = playCount
        self.releaseDate = releaseDate
        
        super.init(id: id, name: name, sortName: sortName, cover: cover, favorite: favorite)
        
        enableOfflineTracking()
    }
    
    override func checkOfflineStatus() {
        Task.detached { [self] in
            self.offline = await OfflineManager.shared.getTrackOfflineStatus(trackId: id)
        }
    }
    override func addObserver() -> [NSObjectProtocol] {
        [NotificationCenter.default.addObserver(forName: NSNotification.TrackDownloadStatusChanged, object: nil, queue: Item.operationQueue) { [weak self] notification in
            if notification.object as? String == self?.id {
                self?.checkOfflineStatus()
            }
        }]
    }
}

// MARK: Helper

extension Track {
    typealias Lyrics = [Double: String?]
    
    struct ReducedAlbum {
        let id: String
        let name: String
        let artists: [ReducedArtist]
    }
    
    struct Index: Comparable, Codable {
        let index: Int
        let disk: Int
        
        static func < (lhs: Index, rhs: Index) -> Bool {
            if lhs.disk == rhs.disk {
                return lhs.index < rhs.index
            } else {
                return lhs.disk < rhs.disk
            }
        }
    }
}
