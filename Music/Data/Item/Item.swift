//
//  Item.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import OSLog

@Observable
class Item: Identifiable {
    let id: String
    let name: String
    let sortName: String?
    
    var cover: Cover?
    var favorite: Bool
    
    // only fetch the offline status when it is required, as it takes some time for albums
    // this is completely transparent
    var _offline: OfflineStatus?
    var offline: OfflineStatus {
        get {
            if let _offline = _offline {
                return _offline
            } else {
                logger.info("Enabled offline tracking for \(self.id) (\(self.name))")
                
                tokens = addObserver()
                checkOfflineStatus()
                
                return .none
            }
        }
    }
    
    private var tokens = [NSObjectProtocol]()
    private let logger = Logger(subsystem: "io.rfk.music", category: "Spotlight")
    
    init(id: String, name: String, sortName: String?, cover: Cover? = nil, favorite: Bool) {
        self.id = id
        self.name = name
        self.sortName = sortName
        self.cover = cover
        self.favorite = favorite
    }
    deinit {
        tokens.forEach {
            NotificationCenter.default.removeObserver($0)
        }
    }
    
    // Has to be here to be overwritable
    public func checkOfflineStatus() {
        self._offline = Item.OfflineStatus.none
    }
    public func addObserver() -> [NSObjectProtocol] {
        []
    }
}

// MARK: Cover

extension Item {
    class Cover: Codable {
        let type: CoverType
        var url: URL
        
        init(type: CoverType, url: URL) {
            self.type = type
            self.url = url
        }
        
        enum CoverType: Codable {
            case jellyfin
            case local
            case remote
        }
    }
}

// MARK: Util

extension Item {
    enum OfflineStatus {
        case none
        case working
        case downloaded
    }
    struct ReducedArtist: Codable {
        let id: String
        let name: String
    }
}

// MARK: Favorite

extension Item {
    func setFavorite(favorite: Bool) async throws {
        try await JellyfinClient.shared.setFavorite(itemId: id, favorite: favorite)
        self.favorite = true
    }
}

// MARK: Offline

extension Item {
    static let operationQueue = OperationQueue()
}

// MARK: Mix

extension Item {
    func startInstantMix() async throws {
        let tracks = try await JellyfinClient.shared.instantMix(itemId: id)
        AudioPlayer.shared.startPlayback(tracks: tracks, startIndex: 0, shuffle: false)
    }
}
