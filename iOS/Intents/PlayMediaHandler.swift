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
        
        switch first.type {
        case .song:
            do {
                let track = try await getTrack(id: identifier)
                startPlayback(tracks: [track], queueLocation: intent.playbackQueueLocation, repeatMode: intent.playbackRepeatMode, shuffle: intent.playShuffled)
            } catch {
                logger.error("Failed to resolve track \(identifier)")
                return .init(code: .failure, userActivity: nil)
            }
        case .album:
            break
        case .artist:
            break
        case .playlist:
            break
        case .station, .musicStation, .algorithmicRadioStation:
            break
        default:
            logger.error("Received intent with unknown media type \(identifier) \(first.type.rawValue)")
            return .init(code: .failureUnknownMediaType, userActivity: nil)
        }
        
        return .init(code: .success, userActivity: nil)
    }
    
    func resolveMediaItems(for intent: INPlayMediaIntent) async -> [INPlayMediaMediaItemResolutionResult] {
        if let search = intent.mediaSearch {
            var result: [Item]?
            
            switch search.mediaType {
            case .song:
                result = try? await searchTracks(name: search.mediaName, albumName: search.albumName, artistName: search.artistName)
                break
            case .album:
                break
            case .artist:
                break
            case .playlist:
                break
                
            case .unknown, .music:
                result = []
                
                if let tracks = try? await searchTracks(name: search.mediaName, albumName: search.albumName, artistName: search.artistName) {
                    result! += tracks
                }
                
                break
            case .station, .musicVideo, .algorithmicRadioStation:
                break
                
            default:
                break
            }
            
            if var result = result, !result.isEmpty {
                if let name = search.mediaName {
                    result.sort { $0.name.levenshteinDistanceScore(to: name) < $1.name.levenshteinDistanceScore(to: name) }
                }
                
                return INPlayMediaMediaItemResolutionResult.successes(with: mapItems(items: result))
            } else {
                return []
            }
        }
        
        return [.unsupported(forReason: .unsupportedMediaType)]
    }
    
    func confirm(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse {
        if !JellyfinClient.shared.isAuthorized {
            return .init(code: .failureRequiringAppLaunch, userActivity: nil)
        }
        
        guard let search = intent.mediaSearch else {
            return .init(code: .failure, userActivity: nil)
        }
        
        if let identifier = search.mediaIdentifier {
            logger.info("Got intent identifier \(identifier)")
        }
        
        logger.info("Confirming intent \(search.mediaName ?? "?")")
        print(search)
        
        // TODO: validate search
        
        return .init(code: .ready, userActivity: nil)
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
        } else {
            AudioPlayer.current.startPlayback(tracks: tracks, startIndex: 0, shuffle: false)
        }
        
        if let shuffle = shuffle {
            AudioPlayer.current.shuffle(shuffle)
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
}
