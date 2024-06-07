//
//  Handler+Play.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 26.04.24.
//

import Foundation
import Intents
import AFFoundation
import AFExtension
import AFNetwork

extension IntentHandler: INPlayMediaIntentHandling {
    func handle(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse {
        return .init(code: .handleInApp, userActivity: nil)
    }
    
    func resolveMediaItems(for intent: INPlayMediaIntent) async -> [INPlayMediaMediaItemResolutionResult] {
        guard JellyfinClient.shared.authorized else {
            return [.unsupported(forReason: .loginRequired)]
        }
        
        if let mediaItems = intent.mediaItems, !mediaItems.isEmpty {
            return INPlayMediaMediaItemResolutionResult.successes(with: mediaItems)
        }
        
        guard let mediaSearch = intent.mediaSearch else {
            if intent.resumePlayback == true {
                return []
            }
            
            return [.unsupported(forReason: .unsupportedMediaType)]
        }
        
        do {
            let items = try await resolveMediaItems(mediaSearch: mediaSearch)
            
            var resolved = [INPlayMediaMediaItemResolutionResult]()
            for item in items {
                resolved.append(.init(mediaItemResolutionResult: .success(with: item)))
            }
            
            return resolved
        } catch SearchError.unsupportedMediaType {
            return [.unsupported(forReason: .unsupportedMediaType)]
        } catch SearchError.notFound {
            return [.unsupported()]
        } catch {
            return [.unsupported(forReason: .serviceUnavailable)]
        }
    }
    
    func resolvePlaybackSpeed(for intent: INPlayMediaIntent) async -> INPlayMediaPlaybackSpeedResolutionResult {
        let speed = intent.playbackSpeed ?? 1
        
        if speed > 1 {
            return .unsupported(forReason: .aboveMaximum)
        } else if speed < 1 {
            return .unsupported(forReason: .belowMinimum)
        }
        
        return .success(with: 1)
    }
}
