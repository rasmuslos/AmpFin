//
//  IntentHandler.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 06.01.24.
//

import Intents
import AFBaseKit
import AFPlaybackKit

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        return self
    }
}

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
