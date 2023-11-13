//
//  PersistenceManager.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData

public struct PersistenceManager {
    public let modelContainer: ModelContainer = {
        let schema = Schema([
            OfflinePlay.self,
            OfflineTrack.self,
            OfflineAlbum.self,
            OfflineLyrics.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}

// MARK: Singleton

extension PersistenceManager {
    public static let shared = PersistenceManager()
}
