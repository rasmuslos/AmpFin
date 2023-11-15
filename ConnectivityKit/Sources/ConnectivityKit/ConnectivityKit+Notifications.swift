//
//  Connectivity+Notifications.swift
//  watchOS
//
//  Created by Rasmus Krämer on 13.11.23.
//

import Foundation

public extension ConnectivityKit {
    static let authenticated = NSNotification.Name("io.rfk.music.login.authenticated")
    static let nowPlayingActivityStarted = NSNotification.Name("io.rfk.music.nowPlaying.started")
}
