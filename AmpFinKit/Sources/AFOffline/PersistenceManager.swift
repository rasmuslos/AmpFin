//
//  PersistenceManager.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData
import AFFoundation

public struct PersistenceManager {
    public let modelContainer: ModelContainer
    
    private init() {
        let schema = Schema([
            OfflineTrack.self,
            OfflineAlbum.self,
            OfflinePlaylist.self,
            
            OfflineLyrics.self,
            OfflinePlay.self,
            OfflineFavorite.self,
        ], version: .init(2, 0, 0))
        
        let modelConfiguration = ModelConfiguration("AmpFin_Migrated", schema: schema, isStoredInMemoryOnly: false, allowsSave: true, groupContainer: AFKIT_ENABLE_ALL_FEATURES ? .identifier("group.io.rfk.ampfin") : .none)
        modelContainer = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    }
}

public extension PersistenceManager {
    static let shared = PersistenceManager()
}
