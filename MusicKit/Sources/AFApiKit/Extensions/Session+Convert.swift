//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFBaseKit

extension Session {
    static func convertFromJellyfin(_ session: JellyfinClient.JellyfinSession) -> Session {
        Session(
            id: session.Id,
            name: session.DeviceName,
            client: session.Client,
            // TODO: this
            nowPlaying: nil,
            queue: [],
            position: Double(session.PlayState.PositionTicks ?? 0) / 10_000_000,
            canSeek: session.PlayState.CanSeek,
            isPaused: session.PlayState.IsPaused,
            isMuted: session.PlayState.IsMuted,
            volumeLevel: Float(session.PlayState.VolumeLevel ?? 0) / 100,
            repeatMode: .none)
    }
}
