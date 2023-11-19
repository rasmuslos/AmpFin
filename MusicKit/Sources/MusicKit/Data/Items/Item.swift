//
//  Item.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import OSLog

@Observable
public class Item: Identifiable {
    public let id: String
    public let name: String
    public let sortName: String?
    
    public var cover: Cover?
    public var favorite: Bool
    
    // only fetch the offline status when it is required, as it takes some time for albums
    // this is completely transparent
    var _offline: OfflineStatus?
    public var offline: OfflineStatus {
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
    func checkOfflineStatus() {
        self._offline = Item.OfflineStatus.none
    }
    func addObserver() -> [NSObjectProtocol] {
        []
    }
}

// MARK: Cover

extension Item {
    public class Cover: Codable {
        public let type: CoverType
        public var url: URL
        
        public init(type: CoverType, url: URL) {
            self.type = type
            self.url = url
        }
        
        public enum CoverType: Codable {
            case jellyfin
            case local
            case remote
        }
    }
}

// MARK: Util

extension Item {
    public enum OfflineStatus {
        case none
        case working
        case downloaded
    }
    public struct ReducedArtist: Codable {
        public let id: String
        public let name: String
    }
}

// MARK: Favorite

extension Item {
    @MainActor
    public func setFavorite(favorite: Bool) async {
        self.favorite = favorite
        
        if let offlineTrack = OfflineManager.shared.getOfflineTrack(trackId: id) {
            offlineTrack.favorite = favorite
        } else if let offlineAlbum = OfflineManager.shared.getOfflineAlbum(albumId: id) {
            offlineAlbum.favorite = favorite
        }
        
        do {
            try await JellyfinClient.shared.setFavorite(itemId: id, favorite: favorite)
        } catch {
            OfflineManager.shared.createOfflineFavorite(itemId: id, favorite: favorite)
        }
    }
}

// MARK: Offline

extension Item {
    static let operationQueue = OperationQueue()
}

// MARK: Mix

extension Item {
    public func startInstantMix() async throws {
        let tracks = try await JellyfinClient.shared.instantMix(itemId: id)
        AudioPlayer.shared.startPlayback(tracks: tracks, startIndex: 0, shuffle: false)
    }
}
