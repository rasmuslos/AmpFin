//
//  File.swift
//
//
//  Created by Rasmus Krämer on 25.12.23.
//

import Foundation

public extension JellyfinClient {
    func delete(identifier: String) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Items/\(identifier)", method: "DELETE"))
    }
    
    func favorite(_ favorite: Bool, identifier: String) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "FavoriteItems/\(identifier)", method: favorite ? "POST" : "DELETE", userPrefix: true))
    }
}
