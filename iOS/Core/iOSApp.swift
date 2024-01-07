//
//  MusicApp.swift
//  Music
//
//  Created by Rasmus Krämer on 05.09.23.
//

import SwiftUI
import SwiftData
import TipKit
import AFBaseKit
import AFOfflineKit
import CoreSpotlight

@main
struct iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        try? Tips.configure([
            .displayFrequency(.daily)
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(PersistenceManager.shared.modelContainer)
    }
}
