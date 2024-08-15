//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFFoundation

internal extension Session {
    convenience init(_ from: JellyfinSession) {
        var nowPlaying: Track?
        
        if let nowPlayingItem = from.NowPlayingItem {
            nowPlaying = .init(nowPlayingItem)
        }
        
        self.init(
            id: from.Id,
            name: from.DeviceName,
            client: from.Client,
            clientId: from.DeviceId,
            nowPlaying: nowPlaying,
            position: Double(from.PlayState.PositionTicks ?? 0) / 10_000_000,
            canSeek: from.PlayState.CanSeek,
            canSetVolume: from.Capabilities.SupportedCommands.contains("SetVolume"),
            isPaused: from.PlayState.IsPaused,
            isMuted: from.PlayState.IsMuted,
            volumeLevel: Float(from.PlayState.VolumeLevel ?? 0) / 100,
            repeatMode: from.PlayState.RepeatMode == "RepeatAll" ? .queue : from.PlayState.RepeatMode == "RepeatOne" ? .track : .none,
            shuffled: from.PlayState.PlaybackOrder == "Shuffle")
    }
}
