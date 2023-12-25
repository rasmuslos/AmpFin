//
//  UserContext.swift
//  Music
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import Intents
import OSLog
import AFBaseKit
import AFPlaybackKit

struct UserContext {
    static let logger = Logger(subsystem: "io.rfk.ampfin", category: "Interactions")
    
    static func updateContext() {
        Task.detached {
            let context = INMediaUserContext()
            // context.numberOfLibraryItems = (try? await OfflineManager.shared.getAllTracks().count) ?? 0
            context.subscriptionStatus = .subscribed
            context.becomeCurrent()
        }
    }
    
    static func donateTrack(_ track: Track, shuffle: Bool, repeatMode: RepeatMode) {
        var artwork: INImage?
        
        if let cover = track.cover, let data = try? Data(contentsOf: cover.url) {
            artwork = INImage(imageData: data)
        }
        
        let mediaItem = INMediaItem(
            identifier: track.id,
            title: track.name,
            type: .song,
            artwork: artwork, 
            artist: track.artistName)
        
        let intent = INPlayMediaIntent(
            mediaItems: [mediaItem],
            mediaContainer: nil,
            playShuffled: shuffle,
            playbackRepeatMode: repeatMode == .queue ? .all : repeatMode == .track ? .one : .none,
            resumePlayback: false,
            playbackQueueLocation: .unknown,
            playbackSpeed: 1.0,
            mediaSearch: nil)
        
        let interaction = INInteraction(intent: intent, response: nil)
        Task.detached {
            do {
                try await interaction.donate()
                logger.info("Donated interaction: \(track.id) (\(track.name))")
            } catch {
                logger.fault("Failed to donate interaction \(error.localizedDescription)")
            }
        }
    }
}
