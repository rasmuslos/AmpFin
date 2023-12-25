//
//  PlaybackReporter.swift
//  Music
//
//  Created by Rasmus Krämer on 24.09.23.
//

import Foundation
import SwiftData
import OSLog
import AFBaseKit

#if canImport(AFOfflineKit)
import AFOfflineKit
#endif

public class PlaybackReporter {
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
    
    func update(positionSeconds: Double, paused: Bool, repeatMode: RepeatMode, shuffled: Bool, volume: Float, scheduled: Bool) {
        if positionSeconds.isFinite && positionSeconds > 0 {
            currentTime = positionSeconds
        }
        
        if scheduled {
            if paused {
                return
            }
            
            if Int(positionSeconds) % 20 != 0 {
                return
            }
        }
        
        Task.detached { [self] in
            try? await JellyfinClient.shared.reportPlaybackProgress(
                trackId: trackId,
                positionSeconds: positionSeconds,
                paused: paused,
                repeatMode: repeatMode,
                shuffled: shuffled,
                volume: volume)
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
        #if canImport(AFOfflineKit)
        let play = OfflinePlay(trackId: trackId, positionSeconds: positionSeconds, time: Date())
        PersistenceManager.shared.modelContainer.mainContext.insert(play)
        #endif
    }
}
