//
//  PlayMediaHandler.swift
//  iOS
//
//  Created by Rasmus Krämer on 05.01.24.
//

import Foundation
import Intents
import OSLog
import AFBase
import AFOffline
import AFPlayback

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
                tracks = [try await MediaResolver.getTrack(id: identifier)]
            case .album:
                tracks = try await MediaResolver.getTracks(albumId: identifier)
                break
            case .artist:
                tracks = try await MediaResolver.getTracks(artistId: identifier)
                break
            case .playlist:
                tracks = try await MediaResolver.getTracks(playlistId: identifier)
                break
            case .station, .musicStation, .algorithmicRadioStation:
                // TODO: this
                break
            default:
                logger.error("Received intent with unknown media type \(identifier) \(first.type.rawValue)")
                return .init(code: .failureUnknownMediaType, userActivity: nil)
            }
            
            guard let tracks = tracks, !tracks.isEmpty else { throw MediaResolver.PlayError.notFound }
            MediaResolver.startPlayback(tracks: tracks, queueLocation: intent.playbackQueueLocation, repeatMode: intent.playbackRepeatMode, shuffle: intent.playShuffled)
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
                result = try? await MediaResolver.searchTracks(name: search.mediaName, albumName: search.albumName, artistName: search.artistName)
                break
            case .album:
                result = try? await MediaResolver.searchAlbums(name: search.mediaName, artistName: search.artistName)
                break
            case .artist:
                result = try? await MediaResolver.searchArtists(name: search.artistName ?? search.mediaName)
                break
            case .playlist:
                result = try? await MediaResolver.searchPlaylists(name: search.mediaName)
                break
                
            case .unknown, .music:
                result = []
                
                if let tracks = try? await MediaResolver.searchTracks(name: search.mediaName, albumName: search.albumName, artistName: search.artistName) {
                    result! += tracks
                }
                if let albums = try? await MediaResolver.searchAlbums(name: search.mediaName, artistName: search.artistName) {
                    result! += albums
                }
                if let artists = try? await MediaResolver.searchArtists(name: search.artistName ?? search.mediaName) {
                    result! += artists
                }
                if let playlists = try? await MediaResolver.searchPlaylists(name: search.mediaName) {
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
                
                return INPlayMediaMediaItemResolutionResult.successes(with: MediaResolver.mapItems(items: result))
            }
        }
        
        return [.unsupported()]
    }
}
