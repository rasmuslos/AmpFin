//
//  File.swift
//
//
//  Created by Rasmus Krämer on 25.12.23.
//

import Foundation

public extension JellyfinClient {
    func setFavorite(itemId: String, favorite: Bool) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "FavoriteItems/\(itemId)", method: favorite ? "POST" : "DELETE", userPrefix: true))
    }
    
    func delete(itemId: String) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Items/\(itemId)", method: "DELETE"))
    }
}
