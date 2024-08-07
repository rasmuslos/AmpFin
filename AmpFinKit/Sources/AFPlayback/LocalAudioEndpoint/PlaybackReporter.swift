//
//  PlaybackReporter.swift
//  Music
//
//  Created by Rasmus Krämer on 24.09.23.
//

import Foundation
import SwiftData
import OSLog
import AFFoundation
import AFNetwork

#if canImport(AFOffline)
import AFOffline
#endif

public final class PlaybackReporter {
    let trackId: String
    var playSessionId: String
    
    var currentTime: Double = 0
    
    init(trackId: String, playSessionId: String, queue: [Track]) {
        self.trackId = trackId
        self.playSessionId = playSessionId
        
        Task {
            try? await JellyfinClient.shared.playbackStarted(identifier: trackId, queueIds: queue.map { $0.id })
        }
    }
    deinit {
        PlaybackReporter.playbackStopped(trackId: trackId, currentTime: currentTime, playSessionId: playSessionId)
    }
    
    func update(positionSeconds: Double, paused: Bool, repeatMode: RepeatMode, shuffled: Bool, volume: Float, scheduled: Bool) {
        guard positionSeconds.isFinite && !positionSeconds.isNaN && positionSeconds > 0 else {
            return
        }
        
        currentTime = positionSeconds
        
        if scheduled {
            if paused {
                return
            }
            
            if Int(positionSeconds) % 20 != 0 {
                return
            }
        }
        
        Task {
            try? await JellyfinClient.shared.progress(
                identifier: trackId,
                position: currentTime,
                paused: paused,
                repeatMode: repeatMode,
                shuffled: shuffled,
                volume: volume)
        }
    }
}

extension PlaybackReporter {
    static func playbackStopped(trackId: String, currentTime: Double, playSessionId: String?) {
        Task {
            do {
                try await JellyfinClient.shared.playbackStopped(identifier: trackId, positionSeconds: currentTime, playSessionId: playSessionId)
            } catch {
                #if canImport(AFOffline)
                OfflineManager.shared.cache(position: currentTime, trackId: trackId)
                #endif
            }
        }
    }
}
