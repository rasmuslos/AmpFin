//
//  File.swift
//
//
//  Created by Rasmus Krämer on 03.06.24.
//

import Foundation
import SwiftData
import AFFoundation

/// This will migrate the previous broken schema into a new one which supports migrations. The old database is kept for a few updates, afterwards it will be deleted, together with this code. At this point attributes like `.unique` can be added to models like `OfflinePlaylist`
private struct LegacyPersistenceManager {
    private let modelContainer: ModelContainer
    
    private init() {
        let schema = Schema([
            Self.OfflineTrack.self,
            Self.OfflineAlbum.self,
            
            OfflinePlaylist.self,
            
            OfflineLyrics.self,
            OfflinePlay.self,
            OfflineFavorite.self,
        ])
        
        let modelConfiguration = ModelConfiguration("AmpFin", schema: schema, isStoredInMemoryOnly: false, allowsSave: true, groupContainer: AFKIT_ENABLE_ALL_FEATURES ? .identifier("group.io.rfk.ampfin") : .none)
        modelContainer = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    }
}

private extension LegacyPersistenceManager {
    // The track models breaks the current schema
    @Model
    final class OfflineTrack {
        @Attribute(.unique)
        let id: String
        let name: String
        
        let releaseDate: Date?
        
        let album: Track.ReducedAlbum
        let artists: [Item.ReducedArtist]
        
        var favorite: Bool
        var runtime: Double
        
        var downloadId: Int?
        
        init(id: String, name: String, releaseDate: Date?, album: Track.ReducedAlbum, artists: [Item.ReducedArtist], favorite: Bool, runtime: Double, downloadId: Int? = nil) {
            self.id = id
            self.name = name
            self.album = album
            self.releaseDate = releaseDate
            self.artists = artists
            self.favorite = favorite
            self.downloadId = downloadId
            self.runtime = runtime
        }
    }
    
    // To prevent future issues and reuse types the album model will be migrated, too.
    @Model
    final class OfflineAlbum {
        @Attribute(.unique)
        let id: String
        let name: String
        
        let overview: String?
        let genres: [String]
        
        let releaseDate: Date?
        let artists: [Item.ReducedArtist]
        
        var favorite: Bool
        
        var childrenIds: [String]
        
        init(id: String, name: String, overview: String?, genres: [String], releaseDate: Date?, artists: [Item.ReducedArtist], favorite: Bool, childrenIds: [String]) {
            self.id = id
            self.name = name
            self.overview = overview
            self.genres = genres
            self.releaseDate = releaseDate
            self.artists = artists
            self.favorite = favorite
            self.childrenIds = childrenIds
        }
    }
    
    // These models don't need to be migrated but i want to make cosmetic changes
    @Model
    final class OfflineFavorite {
        @Attribute(.unique)
        let itemId: String
        var favorite: Bool
        
        init(itemId: String, favorite: Bool) {
            self.itemId = itemId
            self.favorite = favorite
        }
    }
    
    @Model
    final class OfflineLyrics {
        let trackId: String
        let lyrics: Track.Lyrics
        
        init(trackId: String, lyrics: Track.Lyrics) {
            self.trackId = trackId
            self.lyrics = lyrics
        }
    }
    
    @Model
    final class OfflinePlay {
        let trackId: String
        let positionSeconds: Double
        let time: Date
        
        public init(trackId: String, positionSeconds: Double, time: Date) {
            self.trackId = trackId
            self.positionSeconds = positionSeconds
            self.time = time
        }
    }
    
    @Model
    final class OfflinePlaylist {
        let id: String
        public let name: String
        
        public var favorite: Bool
        public var duration: Double
        
        var childrenIds: [String]
        
        init(id: String, name: String, favorite: Bool, duration: Double, childrenIds: [String]) {
            self.id = id
            self.name = name
            self.favorite = favorite
            self.duration = duration
            self.childrenIds = childrenIds
        }
    }
}

private extension LegacyPersistenceManager {
    @MainActor
    func tracks() throws -> [OfflineTrack] {
        return try modelContainer.mainContext.fetch(FetchDescriptor<OfflineTrack>())
    }
    
    @MainActor
    func albums() throws -> [OfflineAlbum] {
        return try modelContainer.mainContext.fetch(FetchDescriptor<OfflineAlbum>())
    }
    
    @MainActor
    func favorites() throws -> [OfflineFavorite] {
        return try modelContainer.mainContext.fetch(FetchDescriptor<OfflineFavorite>())
    }
    
    @MainActor
    func lyrics() throws -> [OfflineLyrics] {
        return try modelContainer.mainContext.fetch(FetchDescriptor<OfflineLyrics>())
    }
    
    @MainActor
    func plays() throws -> [OfflinePlay] {
        return try modelContainer.mainContext.fetch(FetchDescriptor<OfflinePlay>())
    }
    
    @MainActor
    func playlists() throws -> [OfflinePlaylist] {
        return try modelContainer.mainContext.fetch(FetchDescriptor<OfflinePlaylist>())
    }
}

public extension PersistenceManager {
    @MainActor
    func migrate() {
        modelContainer.mainContext.autosaveEnabled = false
        
        try! modelContainer.mainContext.transaction {
            // Run migration:
            
            for track in try! LegacyPersistenceManager.shared.tracks() {
                let migrated = OfflineTrack(
                    id: track.id,
                    name: track.name,
                    released: track.releaseDate,
                    album: .init(albumIdentifier: track.album.id, albumName: track.album.name, albumArtists: track.album.artists.map { .init(artistIdentifier: $0.id, artistName: $0.name) }),
                    artists: track.artists.map { .init(artistIdentifier: $0.id, artistName: $0.name) },
                    favorite: track.favorite,
                    runtime: track.runtime)
                migrated.container = .flac
                
                modelContainer.mainContext.insert(migrated)
            }
            
            for album in try! LegacyPersistenceManager.shared.albums() {
                let migrated = OfflineAlbum(
                    id: album.id,
                    name: album.name,
                    overview: album.overview,
                    genres: album.genres,
                    released: album.releaseDate,
                    artists: album.artists.map { .init(artistIdentifier: $0.id, artistName: $0.name) },
                    favorite: album.favorite,
                    childrenIdentifiers: album.childrenIds)
                
                modelContainer.mainContext.insert(migrated)
            }
            
            // These models can be ported without changes:
            
            for favorite in try! LegacyPersistenceManager.shared.favorites() {
                let migrated = OfflineFavorite(itemIdentifier: favorite.itemId, value: favorite.favorite)
                modelContainer.mainContext.insert(migrated)
            }
            
            for lyrics in try! LegacyPersistenceManager.shared.lyrics() {
                let migrated = OfflineLyrics(trackIdentifier: lyrics.trackId, contents: lyrics.lyrics)
                PersistenceManager.shared.modelContainer.mainContext.insert(migrated)
            }
            
            for play in try! LegacyPersistenceManager.shared.plays() {
                let migrated = OfflinePlay(trackIdentifier: play.trackId, position: play.positionSeconds, date: play.time)
                PersistenceManager.shared.modelContainer.mainContext.insert(migrated)
            }
            
            for playlist in try! LegacyPersistenceManager.shared.playlists() {
                let migrated = OfflinePlaylist(id: playlist.id, name: playlist.name, favorite: playlist.favorite, duration: playlist.duration, childrenIdentifiers: playlist.childrenIds)
                PersistenceManager.shared.modelContainer.mainContext.insert(migrated)
            }
        }
        
        try! modelContainer.mainContext.save()
        modelContainer.mainContext.autosaveEnabled = true
        
        UserDefaults.standard.set(true, forKey: "migratedToNewDatastore_n1u3enjoieqgurfjciuqw0ayj")
    }
}

private extension LegacyPersistenceManager {
    static let shared = LegacyPersistenceManager()
}
