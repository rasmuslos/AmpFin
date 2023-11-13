//
//  watchOSApp.swift
//  watchOS Watch App
//
//  Created by Rasmus Krämer on 13.11.23.
//

import SwiftUI
import WatchKit
import TipKit

@main
struct watchOS_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor var appDelegate: AppDelegate
    
    init() {
        try? Tips.configure([
            .displayFrequency(.daily)
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
