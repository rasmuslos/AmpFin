//
//  Handler+Play.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 26.04.24.
//

import Foundation
import Intents
import AFBase
import AFExtension
import AFPlayback

extension IntentHandler: INPlayMediaIntentHandling {
    /*
     Things that do not need resolving:
     - Queue location
     - Shuffled
     - Repeat
     - Resume playback (not possible)
     */
    
    func handle(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse {
        return .init(code: .handleInApp, userActivity: nil)
    }
    
    func resolveMediaItems(for intent: INPlayMediaIntent) async -> [INPlayMediaMediaItemResolutionResult] {
        guard JellyfinClient.shared.isAuthorized else {
            return [.unsupported(forReason: .loginRequired)]
        }
        
        guard let mediaSearch = intent.mediaSearch else {
            if intent.resumePlayback == true {
                return []
            }
            
            return [.unsupported(forReason: .unsupportedMediaType)]
        }
        guard let primaryName = mediaSearch.mediaName ?? mediaSearch.albumName ?? mediaSearch.artistName else {
            if intent.resumePlayback == true {
                return []
            }
            
            return [.unsupported(forReason: .unsupportedMediaType)]
        }
        
        var results = [Item]()
        let unknownType = mediaSearch.mediaType == .music || mediaSearch.mediaType == .unknown
        
        if !unknownType && !(mediaSearch.mediaType == .album || mediaSearch.mediaType == .artist || mediaSearch.mediaType == .playlist || mediaSearch.mediaType == .song) {
            return [.unsupported(forReason: .unsupportedMediaType)]
        }
        
        if mediaSearch.mediaType == .album || unknownType {
            if let albums = try? await MediaResolver.shared.search(albumName: primaryName, artistName: mediaSearch.artistName) {
                results += albums
            }
        }
        if mediaSearch.mediaType == .artist || unknownType {
            if let artists = try? await MediaResolver.shared.search(artistName: primaryName) {
                results += artists
            }
        }
        if mediaSearch.mediaType == .playlist || unknownType {
            if let playlists = try? await MediaResolver.shared.search(playlistName: primaryName) {
                results += playlists
            }
        }
        if mediaSearch.mediaType == .song || unknownType {
            if let tracks = try? await MediaResolver.shared.search(trackName: primaryName, albumName: mediaSearch.albumName, artistName: mediaSearch.artistName) {
                results += tracks
            }
        }
        
        guard !results.isEmpty else {
            return [.unsupported(forReason: .serviceUnavailable)]
        }
        
        results.sort { $0.name.levenshteinDistanceScore(to: primaryName) > $1.name.levenshteinDistanceScore(to: primaryName) }
        
        let items = MediaResolver.shared.convert(items: results)
        var resolved = [INPlayMediaMediaItemResolutionResult]()
        
        for item in items {
            resolved.append(.init(mediaItemResolutionResult: .success(with: item)))
        }
        
        return resolved
    }
    
    func resolvePlaybackSpeed(for intent: INPlayMediaIntent) async -> INPlayMediaPlaybackSpeedResolutionResult {
        let speed = intent.playbackSpeed ?? 1
        
        if speed > 1 {
            return .unsupported(forReason: .aboveMaximum)
        } else if speed < 1 {
            return .unsupported(forReason: .belowMinimum)
        }
        
        return .success(with: 1)
    }
}
