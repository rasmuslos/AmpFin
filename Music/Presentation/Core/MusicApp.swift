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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    Task.detached {
                        try? await OfflineManager.shared.removeUnfinishedDownloads()
                    }
                }
        }
        .modelContainer(PersistenceManager.shared.modelContainer)
    }
}
