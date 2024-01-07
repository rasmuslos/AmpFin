//
//  PlayMediaHandler.swift
//  iOS
//
//  Created by Rasmus Krämer on 05.01.24.
//

import Foundation
import Intents
import OSLog
import AFBaseKit
import AFOfflineKit
import AFPlaybackKit

class PlayMediaHandler: NSObject, INPlayMediaIntentHandling {
    let logger = Logger(subsystem: "io.rfk.ampfin", category: "SiriPlayIntent")
    
    func handle(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse {
        guard let items = intent.mediaItems, let first = items.first, let identifier = first.identifier else {
            logger.error("Received invalid intent")
            return .init(code: .failure, userActivity: nil)
        }
        
        do {
            var tracks: [Track]?
            
            switch first.type {
            case .song:
                tracks = [try await getTrack(id: identifier)]
            case .album:
                tracks = try await getTracks(albumId: identifier)
                break
            case .artist:
                tracks = try await getTracks(artistId: identifier)
                break
            case .playlist:
                tracks = try await getTracks(playlistId: identifier)
                break
            case .station, .musicStation, .algorithmicRadioStation:
                // TODO: this
                break
            default:
                logger.error("Received intent with unknown media type \(identifier) \(first.type.rawValue)")
                return .init(code: .failureUnknownMediaType, userActivity: nil)
            }
            
            guard let tracks = tracks, !tracks.isEmpty else { throw PlayError.notFound }
            startPlayback(tracks: tracks, queueLocation: intent.playbackQueueLocation, repeatMode: intent.playbackRepeatMode, shuffle: intent.playShuffled)
        } catch {
            logger.error("Failed to resolve tracks \(identifier)")
            return .init(code: .failure, userActivity: nil)
        }
        
        return .init(code: .success, userActivity: nil)
    }
    
    func resolveMediaItems(for intent: INPlayMediaIntent) async -> [INPlayMediaMediaItemResolutionResult] {
        if !JellyfinClient.shared.isAuthorized {
            return [INPlayMediaMediaItemResolutionResult.unsupported(forReason: .loginRequired)]
        }
        
        if let search = intent.mediaSearch {
            var result: [Item]?
            
            switch search.mediaType {
            case .song:
                result = try? await searchTracks(name: search.mediaName, albumName: search.albumName, artistName: search.artistName)
                break
            case .album:
                result = try? await searchAlbums(name: search.mediaName, artistName: search.artistName)
                break
            case .artist:
                result = try? await searchArtists(name: search.artistName ?? search.mediaName)
                break
            case .playlist:
                result = try? await searchPlaylists(name: search.mediaName)
                break
                
            case .unknown, .music:
                result = []
                
                if let tracks = try? await searchTracks(name: search.mediaName, albumName: search.albumName, artistName: search.artistName) {
                    result! += tracks
                }
                if let albums = try? await searchAlbums(name: search.mediaName, artistName: search.artistName) {
                    result! += albums
                }
                if let artists = try? await searchArtists(name: search.artistName ?? search.mediaName) {
                    result! += artists
                }
                if let playlists = try? await searchPlaylists(name: search.mediaName) {
                    result! += playlists
                }
                
                break
                
            case .station, .musicStation, .algorithmicRadioStation:
                if !JellyfinClient.shared.isOnline {
                    return [.unsupported(forReason: .serviceUnavailable)]
                }
                
                // TODO: this
                
                break
                
            default:
                return [.unsupported(forReason: .unsupportedMediaType)]
            }
            
            if var result = result, !result.isEmpty {
                if let name = search.mediaName {
                    result.sort { $0.name.levenshteinDistanceScore(to: name) > $1.name.levenshteinDistanceScore(to: name) }
                }
                
                return INPlayMediaMediaItemResolutionResult.successes(with: mapItems(items: result))
            }
        }
        
        return [.unsupported()]
    }
}

// MARK: Tracks

extension PlayMediaHandler {
    func searchTracks(name: String?, albumName: String?, artistName: String?) async throws -> [Track] {
        guard let name = name else { throw PlayError.notFound }
        
        var tracks = [Track]()
        
        if let offlineTracks = try? await OfflineManager.shared.getTracks(query: name) {
            tracks += offlineTracks
        }
        
        if let fetchedTracks = try? await JellyfinClient.shared.getTracks(query: name) {
            tracks += fetchedTracks.filter { !tracks.contains($0) }
        }
        
        let result = filter(tracks: tracks, albumName: albumName, artistName: artistName)
        if result.isEmpty {
            throw PlayError.notFound
        } else {
            return result
        }
    }
    func filter(tracks: [Track], albumName: String?, artistName: String?) -> [Track] {
        tracks.filter {
            var matches = true
            
            if let albumName = albumName, let name = $0.album.name {
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

extension PlayMediaHandler {
    func searchAlbums(name: String?, artistName: String?) async throws -> [Album] {
        guard let name = name else { throw PlayError.notFound }
        
        var albums = [Album]()
        
        if let offlineAlbums = try? await OfflineManager.shared.getAlbums(query: name) {
            albums += offlineAlbums
        }
        
        if let fetchedAlbums = try? await JellyfinClient.shared.getAlbums(query: name) {
            albums += fetchedAlbums.filter { !albums.contains($0) }
        }
        
        let result = filter(albums: albums, artistName: artistName)
        if result.isEmpty {
            throw PlayError.notFound
        } else {
            return result
        }
    }
    func filter(albums: [Album], artistName: String?) -> [Album] {
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

extension PlayMediaHandler {
    func searchArtists(name: String?) async throws -> [Artist] {
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

extension PlayMediaHandler {
    func searchPlaylists(name: String?) async throws -> [Playlist] {
        guard let name = name else { throw PlayError.notFound }
        
        var result = [Playlist]()
        
        if let offlinePlaylists = try? await OfflineManager.shared.getPlaylists(query: name) {
            result += offlinePlaylists
        }
        
        if let fetchedPlaylists = try? await JellyfinClient.shared.getPlaylists(query: name) {
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

extension PlayMediaHandler {
    func mapItems(items: [Item]) -> [INMediaItem] {
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
    
    func convertImage(cover: Item.Cover?) -> INImage? {
        guard let cover = cover else { return nil }
        
        if cover.type == .local {
            return INImage(url: cover.url)
        }
        
        if let data = try? Data(contentsOf: cover.url) {
            return INImage(imageData: data)
        }
        
        return nil
    }
    func convertType(type: Item.ItemType) -> INMediaItemType {
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

extension PlayMediaHandler {
    func startPlayback(tracks: [Track], queueLocation: INPlaybackQueueLocation?, repeatMode: INPlaybackRepeatMode?, shuffle: Bool?) {
        if let queueLocation = queueLocation, queueLocation == .next || queueLocation == .later {
            AudioPlayer.current.queueTracks(tracks, index: queueLocation == .next ? 0 : AudioPlayer.current.queue.count)
              
            if let shuffle = shuffle {
                AudioPlayer.current.shuffle(shuffle)
            }
        } else {
            AudioPlayer.current.startPlayback(tracks: tracks, startIndex: 0, shuffle: shuffle ?? false, playbackInfo: .init(disable: true))
        }
        
        if let repeatMode = repeatMode {
            switch repeatMode {
            case .all:
                AudioPlayer.current.setRepeatMode(.queue)
                break
            case .one:
                AudioPlayer.current.setRepeatMode(.track)
                break
            case .none:
                AudioPlayer.current.setRepeatMode(.none)
                break
            default:
                break
            }
        }
    }
    
    func getTrack(id: String) async throws -> Track {
        if let track = try? await OfflineManager.shared.getTrack(id: id) {
            return track
        }
        
        return try await JellyfinClient.shared.getTrack(id: id)
    }
    
    func getTracks(albumId: String) async throws -> [Track] {
        if let tracks = try? await OfflineManager.shared.getTracks(albumId: albumId) {
            return tracks
        }
        
        return try await JellyfinClient.shared.getTracks(albumId: albumId)
    }
    func getTracks(artistId: String) async throws -> [Track] {
        if let tracks = try? await OfflineManager.shared.getTracks(artistId: artistId) {
            return tracks.shuffled()
        }
        
        return try await JellyfinClient.shared.getTracks(artistId: artistId).shuffled()
    }
    func getTracks(playlistId: String) async throws -> [Track] {
        if let tracks = try? await OfflineManager.shared.getTracks(playlistId: playlistId) {
            return tracks
        }
        
        return try await JellyfinClient.shared.getTracks(playlistId: playlistId)
    }
}
