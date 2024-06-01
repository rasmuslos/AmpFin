//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 07.01.24.
//

import Foundation
import Intents
import AFNetwork

@available(macOS, unavailable)
public extension INMediaUserContext {
    static func donate() {
        Task {
            let trackCount = try await JellyfinClient.shared.tracks(limit: 1, startIndex: 0, sortOrder: .added, ascending: true).1
            let context = INMediaUserContext()
            
            context.numberOfLibraryItems = trackCount
            context.subscriptionStatus = .subscribed
            context.becomeCurrent()
        }
    }
}
