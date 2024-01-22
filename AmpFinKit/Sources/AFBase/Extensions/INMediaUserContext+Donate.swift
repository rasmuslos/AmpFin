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
            let tracks = try await JellyfinClient.shared.getTracks(limit: 0, sortOrder: .added, ascending: false, favorite: false)
            let context = INMediaUserContext()
            
            context.numberOfLibraryItems = tracks.count
            context.subscriptionStatus = .subscribed
            context.becomeCurrent()
        }
    }
}
