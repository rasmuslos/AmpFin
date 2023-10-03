//
//  UserContext.swift
//  Music
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import Intents

struct UserContext {
    static func updateContext() {
        Task.detached {
            let context = INMediaUserContext()
            context.numberOfLibraryItems = (try? await OfflineManager.shared.getAllTracks().count) ?? 0
            context.subscriptionStatus = .subscribed
            context.becomeCurrent()
        }
    }
}
