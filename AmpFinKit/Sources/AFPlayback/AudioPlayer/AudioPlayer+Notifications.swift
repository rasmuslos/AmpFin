//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 10.07.24.
//

import Foundation

public extension AudioPlayer {
    static let trackDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.track")
    static let playingDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.playing")
    
    static let bufferingDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.buffering")
    static let playbackInfoDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.playbackInfo")
    
    static let timeDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.time")
    static let queueDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.queue")
    static let queueModeDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.queueMode")
    
    static let volumeDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.volume")
    static let bitrateDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.bitrate")
    
    static let routeDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.route")
    static let sourceDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.source")
    
    static let forwardsNotification = Notification.Name("io.rfk.ampfin.audioPlayer.forwards")
    static let backwardsNotification = Notification.Name("io.rfk.ampfin.audioPlayer.backwards")
}
