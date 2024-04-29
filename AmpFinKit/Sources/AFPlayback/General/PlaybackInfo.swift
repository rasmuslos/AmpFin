//
//  File.swift
//
//
//  Created by Rasmus Krämer on 05.01.24.
//

import Foundation
import AFBase
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

extension PlaybackInfo {
    internal func donate() {
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
        
        Task.detached {
            // this is wrong... But apple begs to differ...
            let intent = INPlayMediaIntent(
                mediaItems: [MediaResolver.shared.convert(item: item)],
                mediaContainer: nil,
                playShuffled: AudioPlayer.current.shuffled,
                playbackRepeatMode: repeatMode,
                resumePlayback: false,
                playbackQueueLocation: queueLocation,
                playbackSpeed: 1,
                mediaSearch: .init(mediaName: search))
            
            var activity: NSUserActivity?
            
            if let container = container {
                let activityType: String
                let userInfo: [String: Any]
                
                switch container.type {
                    case .album:
                        activityType = "album"
                        userInfo = [
                            "albumId": container.id,
                        ]
                    case .artist:
                        activityType = "artist"
                        userInfo = [
                            "artistId": container.id,
                        ]
                    case .playlist:
                        activityType = "playlist"
                        userInfo = [
                            "playlistId": container.id,
                        ]
                    case .track:
                        activityType = "track"
                        userInfo = [
                            "trackId": container.id,
                        ]
                }
                
                activity = NSUserActivity(activityType: "io.rfk.ampfin.\(activityType)")
                
                activity!.title = container.name
                activity!.persistentIdentifier = container.id
                activity!.targetContentIdentifier = "\(activityType):\(container.id)"
                
                // Are these journal suggestions?
                activity?.shortcutAvailability = [.sleepJournaling, .sleepMusic]
                
                activity!.isEligibleForPrediction = true
                activity!.userInfo = userInfo
            }
            
            let interaction = INInteraction(intent: intent, response: INPlayMediaIntentResponse(code: .success, userActivity: activity))
            try? await interaction.donate()
        }
    }
}
