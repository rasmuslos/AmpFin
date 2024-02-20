//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation

extension Session {
    public static func convertFromJellyfin(_ session: JellyfinClient.JellyfinSession) -> Session {
        return Session(
            id: session.Id,
            name: session.DeviceName,
            client: session.Client,
            clientId: session.DeviceId,
            nowPlaying: session.NowPlayingItem != nil ? try! Track.convertFromJellyfin(session.NowPlayingItem!) : nil,
            position: Double(session.PlayState.PositionTicks ?? 0) / 10_000_000,
            canSeek: session.PlayState.CanSeek,
            canSetVolume: session.Capabilities.SupportedCommands.contains("SetVolume"),
            isPaused: session.PlayState.IsPaused,
            isMuted: session.PlayState.IsMuted,
            volumeLevel: Float(session.PlayState.VolumeLevel ?? 0) / 100,
            repeatMode: session.PlayState.RepeatMode == "RepeatNone" ? .none : session.PlayState.RepeatMode == "RepeatOne" ? .track : .queue)
    }
}
