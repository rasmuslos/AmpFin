//
//  IntentHandler.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 06.01.24.
//

import Intents
import AFBase
import AFExtension

final internal class IntentHandler: INExtension {
    func resolveMediaItems(mediaSearch: INMediaSearch) async throws -> [INMediaItem] {
        guard let primaryName = mediaSearch.mediaName ?? mediaSearch.albumName ?? mediaSearch.artistName else {
            throw SearchError.unsupportedMediaType
        }
        
        var results = [Item]()
        let unknownType = mediaSearch.mediaType == .music || mediaSearch.mediaType == .unknown
        
        if !unknownType && !(mediaSearch.mediaType == .album || mediaSearch.mediaType == .artist || mediaSearch.mediaType == .playlist || mediaSearch.mediaType == .song) {
            throw SearchError.unsupportedMediaType
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
            throw SearchError.unavailable
        }
        
        results.sort { $0.name.levenshteinDistanceScore(to: primaryName) > $1.name.levenshteinDistanceScore(to: primaryName) }
        
        return MediaResolver.shared.convert(items: results)
    }
    
    enum SearchError: Error {
        case unavailable
        case unsupportedMediaType
    }
}

/*
extension IntentHandler: INAddMediaIntentHandling {
    func handle(intent: INAddMediaIntent) async -> INAddMediaIntentResponse {
        if intent.mediaSearch?.reference == .currentlyPlaying, let destination = intent.mediaDestination, let nowPlaying = AudioPlayer.current.nowPlaying {
            switch destination {
            case .playlist(let name):
                if !JellyfinClient.shared.isOnline { return .init(code: .failure, userActivity: nil) }
                
                guard let playlists = try? await MediaResolver.searchPlaylists(name: name) else { return .init(code: .failure, userActivity: nil) }
                let ordered = playlists.sorted { $0.name.levenshteinDistanceScore(to: name) > $1.name.levenshteinDistanceScore(to: name) }
                guard let playlist = ordered.first else { return .init(code: .failure, userActivity: nil) }
                
                do {
                    try await playlist.add(trackIds: [nowPlaying.id])
                    return .init(code: .success, userActivity: nil)
                } catch {
                    return .init(code: .failure, userActivity: nil)
                }
            default:
                break
            }
        }
        
        return .init(code: .failure, userActivity: nil)
    }
}
*/
