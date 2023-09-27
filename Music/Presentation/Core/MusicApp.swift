//
//  MusicApp.swift
//  Music
//
//  Created by Rasmus Krämer on 05.09.23.
//

import SwiftUI
import SwiftData

@main
struct MusicApp: App {
    /*
    init() {
        Task.detached {
            try? await OfflineManager.shared.removeUnfinishedDownloads()
        }
    }
     */
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(PersistenceManager.shared.modelContainer)
    }
}
