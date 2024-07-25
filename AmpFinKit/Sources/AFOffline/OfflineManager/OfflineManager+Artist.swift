//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 06.01.24.
//

import Foundation
import SwiftData
import AFFoundation

// MARK: Public (Higher Order)

public extension OfflineManager {
    func tracks(artistId identifier: String) throws -> [Track] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.artists.contains(where: { $0.artistIdentifier == identifier }) })
        let tracks = try context.fetch(descriptor)
        
        return tracks.map(Track.init)
    }
}
