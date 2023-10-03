//
//  NSNotification+Player.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import Foundation

extension NSNotification {
    static let QueueUpdated = Notification.Name.init("io.rfk.music.player.queue.updated")
    static let PlayPause = Notification.Name.init("io.rfk.music.player.playPause")
    static let PlaybackChange = Notification.Name.init("io.rfk.music.player.playback.changed")
    static let TrackChange = Notification.Name.init("io.rfk.music.player.changed")
    static let PositionUpdated = Notification.Name.init("io.rfk.music.player.position.updated")
}
