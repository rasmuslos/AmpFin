//
//  AddMediaHandler.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 27.04.24.
//

import Foundation
import Intents
import AmpFinKit
import AFPlayback

final class AddMediaHandler: NSObject, INAddMediaIntentHandling {
    func handle(intent: INAddMediaIntent) async -> INAddMediaIntentResponse {
        let trackId: String
        
        if let mediaItems = intent.mediaItems, let mediaItem = mediaItems.first, let identifier = mediaItem.identifier {
            trackId = identifier
        } else if intent.mediaSearch?.reference == .currentlyPlaying, let nowPlaying = AudioPlayer.current.nowPlaying {
            trackId = nowPlaying.id
        } else {
            return .init(code: .failure, userActivity: nil)
        }
        
        guard let destination = intent.mediaDestination, case INMediaDestination.playlist(let playlistName) = destination else {
            return .init(code: .failure, userActivity: nil)
        }
        
        guard let playlist = try? await MediaResolver.shared.search(playlistName: playlistName).first else {
            return .init(code: .failure, userActivity: nil)
        }
        
        do {
            try await playlist.add(trackIds: [trackId])
            return .init(code: .success, userActivity: nil)
        } catch {
            return .init(code: .failure, userActivity: nil)
        }
    }
}
