//
//  Handler+Add.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 27.04.24.
//

import Foundation
import Intents
import AFBase
import AFExtension

extension IntentHandler: INAddMediaIntentHandling {
    func handle(intent: INAddMediaIntent) async -> INAddMediaIntentResponse {
        .init(code: .handleInApp, userActivity: nil)
    }
    
    func resolveMediaItems(for intent: INAddMediaIntent) async -> [INAddMediaMediaItemResolutionResult] {
        guard JellyfinClient.shared.authorized else {
            return [.unsupported(forReason: .loginRequired)]
        }
        
        guard let mediaSearch = intent.mediaSearch else {
            return [.unsupported(forReason: .unsupportedMediaType)]
        }
        
        if mediaSearch.reference == .currentlyPlaying {
            return []
        }
        
        do {
            let items = try await resolveMediaItems(mediaSearch: mediaSearch)
            
            var resolved = [INAddMediaMediaItemResolutionResult]()
            for item in items {
                resolved.append(.init(mediaItemResolutionResult: .success(with: item)))
            }
            
            return resolved
        } catch {
            print(error)
            if let error = error as? SearchError {
                switch error {
                    case .unavailable:
                        return [.unsupported(forReason: .serviceUnavailable)]
                    case .unsupportedMediaType:
                        return [.unsupported(forReason: .unsupportedMediaType)]
                }
            }
            
            return [.unsupported(forReason: .serviceUnavailable)]
        }
    }
    func resolveMediaDestination(for intent: INAddMediaIntent) async -> INAddMediaMediaDestinationResolutionResult {
        guard let mediaDestination = intent.mediaDestination, let playlistName = mediaDestination.playlistName else {
            return .unsupported(forReason: .playlistNameNotFound)
        }
        
        do {
            var playlists = try await MediaResolver.shared.search(playlistName: playlistName)
            playlists.sort { $0.name.levenshteinDistanceScore(to: playlistName) > $1.name.levenshteinDistanceScore(to: playlistName) }
            
            guard let playlist = playlists.first else {
                throw MediaResolver.ResolveError.missing
            }
            
            return .success(with: .playlist(playlist.name))
        } catch {}
        
        return .unsupported(forReason: .playlistNameNotFound)
    }
}
