//
//  AppDelegate.swift
//  watchOS
//
//  Created by Rasmus Krämer on 13.11.23.
//

import WatchKit
import ConnectivityKit

class AppDelegate: NSObject, WKApplicationDelegate {
    func handleRemoteNowPlayingActivity() {
        NotificationCenter.default.post(name: ConnectivityKit.nowPlayingActivityStarted, object: nil)
    }
}
