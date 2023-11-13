//
//  NSNotification+Player.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import Foundation

extension AudioPlayer {
    public static let queueUpdated = Notification.Name.init("io.rfk.music.player.queue.updated")
    
    public static let playPause = Notification.Name.init("io.rfk.music.player.playPause")
    public static let positionUpdated = Notification.Name.init("io.rfk.music.player.position.updated")
    
    public static let playbackChange = Notification.Name.init("io.rfk.music.player.playback.changed")
    public static let trackChange = Notification.Name.init("io.rfk.music.player.changed")
}
