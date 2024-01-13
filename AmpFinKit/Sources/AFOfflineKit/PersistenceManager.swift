//
//  PersistenceManager.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData
import AFBaseKit

public struct PersistenceManager {
    public let modelContainer: ModelContainer = {
        let schema = Schema([
            OfflineTrack.self,
            OfflineAlbum.self,
            OfflinePlaylist.self,
            
            OfflineLyrics.self,
            OfflinePlay.self,
            OfflineFavorite.self,
        ])
        #if DISABLE_APP_GROUP
        let modelConfiguration = ModelConfiguration("AmpFin", schema: schema, isStoredInMemoryOnly: false, allowsSave: true, groupContainer: .identifier("group.io.rfk.ampfin"))
        #else
        let modelConfiguration = ModelConfiguration("AmpFin", schema: schema, isStoredInMemoryOnly: false, allowsSave: true)
        #endif
        
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
