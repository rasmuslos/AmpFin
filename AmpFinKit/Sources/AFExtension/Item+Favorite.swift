//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFBase

#if canImport(AFOffline)
import AFOffline
#endif

// MARK: Favorite

extension Item {
    @MainActor
    public func setFavorite(favorite: Bool) async {
        self.favorite = favorite

        #if canImport(AFOffline)
        OfflineManager.shared.updateOfflineFavorite(itemId: id, favorite: favorite)
        
        do {
            try await JellyfinClient.shared.setFavorite(itemId: id, favorite: favorite)
        } catch {
            OfflineManager.shared.cacheFavorite(itemId: id, favorite: favorite)
        }
        #endif
        
        try? await JellyfinClient.shared.setFavorite(itemId: id, favorite: favorite)
        
        NotificationCenter.default.post(name: Self.affinityChanged, object: id, userInfo: [
            "favorite": favorite,
        ])
    }
}
