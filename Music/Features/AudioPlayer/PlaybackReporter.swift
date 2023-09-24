//
//  PlaybackReporter.swift
//  Music
//
//  Created by Rasmus Krämer on 24.09.23.
//

import Foundation
import SwiftData

class PlaybackReporter {
    let trackId: String
    
    var endReported = false
    
    init(trackId: String) {
        self.trackId = trackId
        reportPlaybackStart()
    }
    
    func update(positionSeconds: Double, paused: Bool, sheduled: Bool) {
        if sheduled {
            if paused {
                return
            }
            
            if Int(positionSeconds) % 20 != 0 {
                return
            }
        }
        
        reportPlaybackProgress(positionSeconds: positionSeconds, paused: paused)
    }
    
    func ended(positionSeconds: Double) {
        if positionSeconds < 3 || endReported {
            return
        }
        
        endReported = true
        reportPlaybackEnded(positionSeconds: positionSeconds)
    }
}

// MARK: Helper

extension PlaybackReporter {
    private func reportPlaybackStart() {
        Task.detached { [self] in
            try? await JellyfinClient.shared.reportPlaybackStarted(trackId: trackId)
        }
    }
    private func reportPlaybackProgress(positionSeconds: Double, paused: Bool) {
        Task.detached { [self] in
            try? await JellyfinClient.shared.reportPlaybackProgress(trackId: trackId, positionSeconds: positionSeconds, paused: paused)
        }
    }
    private func reportPlaybackEnded(positionSeconds: Double) {
        Task.detached { [self] in
            do {
                try await JellyfinClient.shared.reportPlaybackStopped(trackId: trackId, positionSeconds: positionSeconds)
            } catch {
                await cacheReport(positionSeconds: positionSeconds)
            }
        }
    }
}

// MARK: Offline

extension PlaybackReporter {
    @MainActor
    func cacheReport(positionSeconds: Double) {
        let play = OfflinePlay(trackId: trackId, positionSeconds: positionSeconds)
        PersistenceManager.shared.modelContainer.mainContext.insert(play)
    }
    
    static func syncPlaysToJellyfinServer() {
        Task.detached { @MainActor in
            let plays = try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflinePlay>())
            
            for play in plays {
                do {
                    try await JellyfinClient.shared.reportPlaybackStopped(trackId: play.trackId, positionSeconds: play.positionSeconds)
                    PersistenceManager.shared.modelContainer.mainContext.delete(play)
                } catch {
                    print("error while syncing play to jellyfin server", play)
                }
            }
        }
    }
}
