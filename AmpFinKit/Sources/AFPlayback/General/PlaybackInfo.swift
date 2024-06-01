//
//  File.swift
//
//
//  Created by Rasmus Krämer on 05.01.24.
//

import Foundation
import AFFoundation
import AFExtension
import Intents

public struct PlaybackInfo {
    public var tracks: [Track]!
    public let container: Item?
    
    public let search: String?
    
    var queueLocation: INPlaybackQueueLocation
    var preventDonation: Bool
    
    public init(container: Item?, search: String? = "", queueLocation: INPlaybackQueueLocation = .now, preventDonation: Bool = false) {
        self.container = container
        
        self.search = search
        
        self.queueLocation = queueLocation
        self.preventDonation = preventDonation
    }
}

#if os(macOS)
public enum INPlaybackQueueLocation {
    case now
    case next
    case later
}
#endif

@available(macOS, unavailable)
extension PlaybackInfo {
    internal func donate() {
        Task {
            if preventDonation { return }
            
            guard let item = container ?? tracks.first else {
                return
            }
            
            let repeatMode: INPlaybackRepeatMode
            
            switch AudioPlayer.current.repeatMode {
                case .none:
                    repeatMode = .none
                    break
                case .track:
                    repeatMode = .one
                    break
                case .queue:
                    repeatMode = .all
                    break
            }
            
            #if !os(macOS)
            // this is wrong... But apple begs to differ...
            let intent = INPlayMediaIntent(
                mediaItems: [await MediaResolver.shared.convert(item: item)],
                mediaContainer: nil,
                playShuffled: AudioPlayer.current.shuffled,
                playbackRepeatMode: repeatMode,
                resumePlayback: false,
                playbackQueueLocation: queueLocation,
                playbackSpeed: 1,
                mediaSearch: .init(mediaName: search))
            
            let activityType: String
            let userInfo: [String: Any]
            
            switch item.type {
                case .album:
                    activityType = "album"
                    userInfo = [
                        "albumId": item.id,
                    ]
                case .artist:
                    activityType = "artist"
                    userInfo = [
                        "artistId": item.id,
                    ]
                case .playlist:
                    activityType = "playlist"
                    userInfo = [
                        "playlistId": item.id,
                    ]
                case .track:
                    activityType = "track"
                    userInfo = [
                        "trackId": item.id,
                    ]
            }
            
            let activity = NSUserActivity(activityType: "io.rfk.ampfin.\(activityType)")
            
            activity.title = item.name
            activity.persistentIdentifier = item.id
            activity.targetContentIdentifier = "\(activityType):\(item.id)"
            
            // Are these journal suggestions?
            activity.shortcutAvailability = [.sleepJournaling, .sleepMusic]
            
            activity.isEligibleForPrediction = true
            activity.userInfo = userInfo
            
            let interaction = INInteraction(intent: intent, response: INPlayMediaIntentResponse(code: .success, userActivity: activity))
            try? await interaction.donate()
            #endif
        }
    }
}
