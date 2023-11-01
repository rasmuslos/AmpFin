//
//  NSNotification+Player.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import Foundation

extension AudioPlayer {
    static let queueUpdated = Notification.Name.init("io.rfk.music.player.queue.updated")
    
    static let playPause = Notification.Name.init("io.rfk.music.player.playPause")
    static let positionUpdated = Notification.Name.init("io.rfk.music.player.position.updated")
    
    static let playbackChange = Notification.Name.init("io.rfk.music.player.playback.changed")
    static let trackChange = Notification.Name.init("io.rfk.music.player.changed")
}
