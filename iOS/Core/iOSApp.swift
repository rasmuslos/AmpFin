//
//  MusicApp.swift
//  Music
//
//  Created by Rasmus Krämer on 05.09.23.
//

import SwiftUI
import SwiftData
import TipKit
import MusicKit
import ConnectivityKit

@main
struct MusicApp: App {
    init() {
        try? Tips.configure([
            .displayFrequency(.daily)
        ])
        
        ConnectivityKit.shared.setup()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(PersistenceManager.shared.modelContainer)
    }
}
