//
//  PlaybackReporter.swift
//  Music
//
//  Created by Rasmus Krämer on 24.09.23.
//

import Foundation
import SwiftData
import OSLog

class PlaybackReporter {
    static let logger = Logger(subsystem: "io.rfk.music", category: "Reporting")
    
    let trackId: String
    
    var currentTime: Double = 0
    
    init(trackId: String) {
        self.trackId = trackId
        
        Task.detached {
            try? await JellyfinClient.shared.reportPlaybackStarted(trackId: trackId)
        }
    }
    deinit {
        PlaybackReporter.playbackStopped(trackId: trackId, currentTime: currentTime)
    }
    
    func update(positionSeconds: Double, paused: Bool, sheduled: Bool) {
        if positionSeconds.isFinite && positionSeconds > 0 {
            currentTime = positionSeconds
        }
        
        if sheduled {
            if paused {
                return
            }
            
            if Int(positionSeconds) % 20 != 0 {
                return
            }
        }
        
        Task.detached { [self] in
            try? await JellyfinClient.shared.reportPlaybackProgress(trackId: trackId, positionSeconds: positionSeconds, paused: paused)
        }
    }
}

// MARK: Playback stop

extension PlaybackReporter {
    static func playbackStopped(trackId: String, currentTime: Double) {
        Task.detached { [self] in
            do {
                try await JellyfinClient.shared.reportPlaybackStopped(trackId: trackId, positionSeconds: currentTime)
            } catch {
                await cacheReport(trackId: trackId, positionSeconds: currentTime)
            }
        }
    }
}

// MARK: Offline

extension PlaybackReporter {
    @MainActor
    static func cacheReport(trackId: String, positionSeconds: Double) {
        let play = OfflinePlay(trackId: trackId, positionSeconds: positionSeconds, time: Date())
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
                    logger.fault("Error while syncing play to Jellyfin server \(play.trackId) (\(play.positionSeconds)")
                }
            }
        }
    }
}
