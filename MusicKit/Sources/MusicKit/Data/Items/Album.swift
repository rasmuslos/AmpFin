//
//  Album.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

public class Album: Item {
    public let overview: String?
    public let genres: [String]
    
    public let releaseDate: Date?
    public let artists: [ReducedArtist]
    
    public let playCount: Int
    
    init(id: String, name: String, sortName: String?, cover: Cover? = nil, favorite: Bool, overview: String?, genres: [String], releaseDate: Date?, artists: [ReducedArtist], playCount: Int) {
        self.overview = overview
        self.genres = genres
        self.releaseDate = releaseDate
        self.artists = artists
        self.playCount = playCount
        
        super.init(id: id, name: name, sortName: sortName, cover: cover, favorite: favorite)
    }
    
    override func checkOfflineStatus() {
        Task.detached { [self] in
            self._offline = await OfflineManager.shared.getAlbumOfflineStatus(albumId: id)
        }
    }
    override func addObserver() -> [NSObjectProtocol] {
        [NotificationCenter.default.addObserver(forName: OfflineManager.albumDownloadStatusChanged, object: nil, queue: Item.operationQueue) { [weak self] notification in
            if notification.object as? String == self?.id {
                self?.checkOfflineStatus()
            }
        }]
    }
}

// MARK: Convenience

extension Album {
    public var artistName: String {
        get {
            // for some truly stupid reasons string catalogs do not work here. I have no idea why
            artists.map { $0.name }.joined(separator: String(localized: ", "))
        }
    }
}
