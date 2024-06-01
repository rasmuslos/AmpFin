//
//  File.swift
//
//
//  Created by Rasmus Krämer on 15.05.24.
//

import Foundation

internal struct JellyfinSession: Codable {
    let Id: String
    let Client: String
    
    let DeviceId: String
    let DeviceName: String
    
    let PlayState: JellyfinPlayState
    let Capabilities: JellyfinCapabilities
    
    let NowPlayingItem: JellyfinItem?
    // let NowPlayingQueueFullItems: [JellyfinTrackItem]
    
    struct JellyfinPlayState: Codable {
        let PositionTicks: Int64?
        let CanSeek: Bool
        let IsPaused: Bool
        let IsMuted: Bool
        let VolumeLevel: Int?
        let RepeatMode: String
        // only available in 10.9
        let PlaybackOrder: String?
    }
    struct JellyfinCapabilities: Codable {
        let PlayableMediaTypes: [String]
        let SupportedCommands: [String]
        let SupportsMediaControl: Bool
    }
}
