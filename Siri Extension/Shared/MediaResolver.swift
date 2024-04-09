//
//  MediaResolver.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 13.01.24.
//

import Foundation
import Intents
import AFBase
import AFOffline
import AFPlayback

struct MediaResolver {
}

// MARK: Tracks

extension MediaResolver {
    static func searchTracks(name: String?, albumName: String?, artistName: String?) async throws -> [Track] {
        guard let name = name else { throw PlayError.notFound }
        
        var tracks = [Track]()
        
        if let offlineTracks = try? await OfflineManager.shared.getTracks(query: name) {
            tracks += offlineTracks
        }
        
        if !UserDefaults.standard.bool(forKey: "siriOfflineMode"), let fetchedTracks = try? await JellyfinClient.shared.getTracks(query: name) {
            tracks += fetchedTracks.filter { !tracks.contains($0) }
        }
        
        let result = filter(tracks: tracks, albumName: albumName, artistName: artistName)
        if result.isEmpty {
            throw PlayError.notFound
        } else {
            return result
        }
    }
    private static func filter(tracks: [Track], albumName: String?, artistName: String?) -> [Track] {
        tracks.filter {
            var matches = true
            
            if let albumName = albumName, let name = $0.album.albumName {
                if !name.localizedStandardContains(albumName) {
                    matches = false
                }
            }
            
            if let artistName = artistName {
                if !$0.artists.reduce(false, { $0 || $1.name.localizedStandardContains(artistName) }) {
                    matches = false
                }
            }
            
            return matches
        }
    }
}

// MARK: Albums

extension MediaResolver {
    static func searchAlbums(name: String?, artistName: String?) async throws -> [Album] {
        guard let name = name else { throw PlayError.notFound }
        
        var albums = [Album]()
        
        if let offlineAlbums = try? await OfflineManager.shared.getAlbums(query: name) {
            albums += offlineAlbums
        }
        
        if !UserDefaults.standard.bool(forKey: "siriOfflineMode"), let fetchedAlbums = try? await JellyfinClient.shared.getAlbums(query: name) {
            albums += fetchedAlbums.filter { !albums.contains($0) }
        }
        
        let result = filter(albums: albums, artistName: artistName)
        if result.isEmpty {
            throw PlayError.notFound
        } else {
            return result
        }
    }
    private static func filter(albums: [Album], artistName: String?) -> [Album] {
        albums.filter {
            if let artistName = artistName {
                if !$0.artists.reduce(false, { $0 || $1.name.localizedStandardContains(artistName) }) {
                    return false
                }
            }
            
            return true
        }
    }
}

// MARK: Artists

extension MediaResolver {
    static func searchArtists(name: String?) async throws -> [Artist] {
        guard let name = name else { throw PlayError.notFound }
        
        let result = try await JellyfinClient.shared.getArtists(query: name)
        
        if result.isEmpty {
            throw PlayError.notFound
        } else {
            return result
        }
    }
}

// MARK: Playlists

extension MediaResolver {
    static func searchPlaylists(name: String?) async throws -> [Playlist] {
        guard let name = name else { throw PlayError.notFound }
        
        var result = [Playlist]()
        
        if let offlinePlaylists = try? await OfflineManager.shared.getPlaylists(query: name) {
            result += offlinePlaylists
        }
        
        if !UserDefaults.standard.bool(forKey: "siriOfflineMode"), let fetchedPlaylists = try? await JellyfinClient.shared.getPlaylists(query: name) {
            result += fetchedPlaylists.filter { !result.contains($0) }
        }
        
        if result.isEmpty {
            throw PlayError.notFound
        } else {
            return result
        }
    }
}

// MARK: AFItem --> INItem

extension MediaResolver {
    static func mapItems(items: [Item]) -> [INMediaItem] {
        items.map {
            var artist: String?
            
            if let track = $0 as? Track {
                artist = track.artistName
            } else if let album = $0 as? Album {
                artist = album.artistName
            }
            
            return INMediaItem(
                identifier: $0.id,
                title: $0.name,
                type: convertType(type: $0.type),
                artwork: convertImage(cover: $0.cover),
                artist: artist)
        }
    }
    
    private static func convertImage(cover: Item.Cover?) -> INImage? {
        guard let cover = cover else { return nil }
        
        if cover.type == .local {
            return INImage(url: cover.url)
        }
        
        if let data = try? Data(contentsOf: cover.url) {
            return INImage(imageData: data)
        }
        
        return nil
    }
    private static func convertType(type: Item.ItemType) -> INMediaItemType {
        switch type {
            case .album:
                return .album
            case .artist:
                return .artist
            case .track:
                return .song
            case .playlist:
                return .playlist
        }
    }
    
    enum PlayError: Error {
        case notFound
    }
}

// MARK: INItem --> AFItem

extension MediaResolver {
    static func startPlayback(tracks: [Track], queueLocation: INPlaybackQueueLocation?, repeatMode: INPlaybackRepeatMode?, shuffle: Bool?) {
        if let queueLocation = queueLocation, queueLocation == .next || queueLocation == .later {
            AudioPlayer.current.queueTracks(tracks, index: queueLocation == .next ? 0 : AudioPlayer.current.queue.count)
            
            if let shuffle = shuffle {
                AudioPlayer.current.shuffled = shuffle
            }
        } else {
            AudioPlayer.current.startPlayback(tracks: tracks, startIndex: 0, shuffle: shuffle ?? false, playbackInfo: .init(disable: true))
        }
        
        if let repeatMode = repeatMode {
            switch repeatMode {
                case .all:
                    AudioPlayer.current.repeatMode = .queue
                    break
                case .one:
                    AudioPlayer.current.repeatMode = .track
                    break
                case .none:
                    AudioPlayer.current.repeatMode = .none
                    break
                default:
                    break
            }
        }
    }
    
    static func getTrack(id: String) async throws -> Track {
        if let track = try? await OfflineManager.shared.getTrack(id: id) {
            return track
        }
        
        return try await JellyfinClient.shared.getTrack(id: id)
    }
    
    static func getTracks(albumId: String) async throws -> [Track] {
        if let tracks = try? await OfflineManager.shared.getTracks(albumId: albumId) {
            return tracks
        }
        
        return try await JellyfinClient.shared.getTracks(albumId: albumId)
    }
    static func getTracks(artistId: String) async throws -> [Track] {
        if let tracks = try? await OfflineManager.shared.getTracks(artistId: artistId) {
            return tracks.shuffled()
        }
        
        return try await JellyfinClient.shared.getTracks(artistId: artistId).shuffled()
    }
    static func getTracks(playlistId: String) async throws -> [Track] {
        if let tracks = try? await OfflineManager.shared.getTracks(playlistId: playlistId) {
            return tracks
        }
        
        return try await JellyfinClient.shared.getTracks(playlistId: playlistId)
    }
}
