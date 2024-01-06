//
//  PlayMediaHandler.swift
//  iOS
//
//  Created by Rasmus Krämer on 05.01.24.
//

import Foundation
import Intents

import AFBaseKit
import AFPlaybackKit

class PlayMediaHandler: NSObject, INPlayMediaIntentHandling {
    func handle(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse {
        print("b")
        
        if let tracks = try? await JellyfinClient.shared.getTracks(limit: 20, sortOrder: .added, ascending: false, favorite: true) {
            AudioPlayer.current.startPlayback(tracks: tracks, startIndex: 0, shuffle: false)
        }
        
        return .init(code: .success, userActivity: nil)
    }
    
    func resolveMediaItems(for intent: INPlayMediaIntent) async -> [INPlayMediaMediaItemResolutionResult] {
        print("a")
        
        return INPlayMediaMediaItemResolutionResult.successes(with: [
            INMediaItem(identifier: "io.rfk.ampfin.test", title: "Test Item", type: .song, artwork: nil, artist: "Test Artist")
        ])
    }
    
    func resolvePlayShuffled(for intent: INPlayMediaIntent) async -> INBooleanResolutionResult {
        .success(with: false)
    }
    
    func resolvePlaybackQueueLocation(for intent: INPlayMediaIntent) async -> INPlaybackQueueLocationResolutionResult {
        .success(with: .now)
    }
    
    func resolvePlaybackRepeatMode(for intent: INPlayMediaIntent) async -> INPlaybackRepeatModeResolutionResult {
        .success(with: .none)
    }
    
    func resolvePlaybackSpeed(for intent: INPlayMediaIntent) async -> INPlayMediaPlaybackSpeedResolutionResult {
        .success(with: 1)
    }
    
    func resolveResumePlayback(for intent: INPlayMediaIntent) async -> INBooleanResolutionResult {
        .success(with: true)
    }
}
