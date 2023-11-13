//
//  AppDelegate.swift
//  watchOS
//
//  Created by Rasmus Krämer on 13.11.23.
//

import WatchKit

class AppDelegate: NSObject, WKApplicationDelegate {
    func handleRemoteNowPlayingActivity() {
        NotificationCenter.default.post(name: ConnectivityViewModel.nowPlayingActivityStarted, object: nil)
    }
}
