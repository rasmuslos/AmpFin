//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 06.01.24.
//

import Foundation
import SwiftData
import AFFoundation

public extension OfflineManager {
    @MainActor
    func tracks(artistId identifier: String) throws -> [Track] {
        let descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate {
            $0.artists.contains(where: { $0.artistIdentifier == identifier })
        })
        let tracks = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
        
        return tracks.map(Track.init)
    }
}
