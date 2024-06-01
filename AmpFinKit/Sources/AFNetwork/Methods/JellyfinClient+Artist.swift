//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFFoundation

public extension JellyfinClient {
    func artists(limit: Int, startIndex: Int, albumOnly: Bool, search: String?) async throws -> ([Artist], Int) {
        var query = [
            URLQueryItem(name: "SortBy", value: ItemSortOrder.name.value),
            URLQueryItem(name: "SortOrder", value: "Ascending")
        ]
        
        if limit > 0 {
            query.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if startIndex > 0 {
            query.append(URLQueryItem(name: "startIndex", value: String(startIndex)))
        }
        if let search = search {
            query.append(URLQueryItem(name: "searchTerm", value: search))
        }
        
        let response = try await request(ClientRequest<JellyfinItemsResponse>(path: albumOnly ? "Artists/AlbumArtists" : "Artists", method: "GET", query: query, userId: true))
        return (response.Items.map(Artist.init), response.TotalRecordCount)
    }
    
    func artists(search: String) async throws -> [Artist] {
        let response = try await request(ClientRequest<JellyfinItemsResponse>(path: "Artists", method: "GET", query: [
            URLQueryItem(name: "Limit", value: "20"),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "searchTerm", value: search),
        ], userId: true))
        
        return response.Items.map(Artist.init)
    }
    
    func artist(identifier: String) async throws -> Artist {
        guard let artist = try await request(ClientRequest<JellyfinItem?>(path: "Items/\(identifier)", method: "GET", userPrefix: true)) else {
            throw ClientError.invalidResponse
        }
        
        return .init(artist)
    }
}
