//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 07.01.24.
//

import Foundation
import Intents

extension INMediaUserContext {
    public static func donate() {
        Task.detached {
            // we don't need to get all tracks as Jellyfin will return the total amount of tracks
            let tracks = try await JellyfinClient.shared.getTracks(limit: 0, startIndex: 0, sortOrder: .added, ascending: false, favorite: false)
            let context = INMediaUserContext()
            
            context.numberOfLibraryItems = tracks.1
            context.subscriptionStatus = .subscribed
            context.becomeCurrent()
        }
    }
}
