//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 25.12.23.
//

import Foundation

extension AudioPlayer {
    public static let playbackStarted = Notification.Name.init("io.rfk.ampfin.player.started")
    public static let queueUpdated = Notification.Name.init("io.rfk.ampfin.player.queue.updated")
    
    public static let playPause = Notification.Name.init("io.rfk.ampfin.player.playPause")
    public static let positionUpdated = Notification.Name.init("io.rfk.ampfin.player.position.updated")
    
    public static let trackChange = Notification.Name.init("io.rfk.ampfin.player.changed")
    public static let volumeChange = Notification.Name.init("io.rfk.ampfin.volume.changed")
}
