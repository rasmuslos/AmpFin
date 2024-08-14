//
//  PlayMediaHandler.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 26.04.24.
//

import Foundation
import Intents
import AmpFinKit
import AFPlayback

final class PlayMediaHandler: NSObject, INPlayMediaIntentHandling {
    func handle(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse {
        if intent.resumePlayback == true && AudioPlayer.current.nowPlaying != nil {
            AudioPlayer.current.playing = true
            return .init(code: .success, userActivity: nil)
        }
        
        guard let mediaItem = intent.mediaItems?.first, let identifier = mediaItem.identifier else {
            return .init(code: .failure, userActivity: nil)
        }
        
        var tracks = [Track]()
        
        do {
            if mediaItem.type == .album {
                tracks = try await MediaResolver.shared.tracks(albumId: identifier)
            } else if mediaItem.type == .artist {
                tracks = try await MediaResolver.shared.tracks(artistId: identifier)
            } else if mediaItem.type == .playlist {
                tracks = try await MediaResolver.shared.tracks(playlistId: identifier)
            } else if mediaItem.type == .song {
                tracks = [try await MediaResolver.shared.track(id: identifier)]
            }
            
            guard !tracks.isEmpty else {
                throw MediaResolver.ResolveError.empty
            }
            
            if intent.playbackQueueLocation == .unknown || intent.playbackQueueLocation == .now {
                AudioPlayer.current.startPlayback(tracks: tracks, startIndex: 0, shuffle: intent.playShuffled ?? false, playbackInfo: .init(container: nil, preventDonation: true))
            } else {
                AudioPlayer.current.queue(tracks, after: intent.playbackQueueLocation == .next ? 0 : AudioPlayer.current.queue.count, playbackInfo: .init(container: nil, preventDonation: true))
                
                if let shuffled = intent.playShuffled {
                    AudioPlayer.current.shuffled = shuffled
                }
            }
            
            switch intent.playbackRepeatMode {
                case .none:
                    AudioPlayer.current.repeatMode = .none
                    break
                case .all:
                    AudioPlayer.current.repeatMode = .queue
                    break
                case .one:
                    AudioPlayer.current.repeatMode = .track
                    break
                default:
                    break
            }
            
            return .init(code: .success, userActivity: nil)
        } catch {
            return .init(code: .failure, userActivity: nil)
        }
    }
}
