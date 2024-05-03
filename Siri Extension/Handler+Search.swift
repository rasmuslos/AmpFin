//
//  Handler+Search.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 26.04.24.
//

import Foundation
import Intents
import AFBase

extension IntentHandler: INSearchForMediaIntentHandling {
    func handle(intent: INSearchForMediaIntent) async -> INSearchForMediaIntentResponse {
        guard let item = intent.mediaItems?.first, let identifier = item.identifier else {
            return .init(code: .failure, userActivity: nil)
        }
        
        var activity: NSUserActivity
        
        switch item.type {
            case .album:
                activity = .init(activityType: "io.rfk.ampfin.album")
                activity.userInfo = [
                    "albumId": identifier,
                ]
            case .artist:
                activity = .init(activityType: "io.rfk.ampfin.artist")
                activity.userInfo = [
                    "artistId": identifier,
                ]
            case .playlist:
                activity = .init(activityType: "io.rfk.ampfin.playlist")
                activity.userInfo = [
                    "playlistId": identifier,
                ]
            case .song:
                activity = .init(activityType: "io.rfk.ampfin.track")
                activity.userInfo = [
                    "trackId": identifier,
                ]
                
            default:
                return .init(code: .failure, userActivity: nil)
        }
        
        activity.title = item.title
        activity.persistentIdentifier = identifier
        
        return .init(code: .continueInApp, userActivity: activity)
    }
    
    func resolveMediaItems(for intent: INSearchForMediaIntent) async -> [INSearchForMediaMediaItemResolutionResult] {
        guard JellyfinClient.shared.authorized else {
            return [.unsupported(forReason: .loginRequired)]
        }
        
        guard let mediaSearch = intent.mediaSearch else {
            return [.unsupported(forReason: .unsupportedMediaType)]
        }
        
        do {
            let items = try await resolveMediaItems(mediaSearch: mediaSearch)
            
            var resolved = [INSearchForMediaMediaItemResolutionResult]()
            for item in items {
                resolved.append(.init(mediaItemResolutionResult: .success(with: item)))
            }
            
            return resolved
        } catch {
            if let error = error as? SearchError {
                switch error {
                    case .unavailable:
                        return [.unsupported(forReason: .serviceUnavailable)]
                    case .unsupportedMediaType:
                        return [.unsupported(forReason: .unsupportedMediaType)]
                }
            }
            
            return [.unsupported(forReason: .serviceUnavailable)]
        }
    }
}
