//
//  JellyfinClient+Items.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import AFFoundation

private let albumQuery = [
    URLQueryItem(name: "Recursive", value: "true"),
    URLQueryItem(name: "ImageTypeLimit", value: "1"),
    URLQueryItem(name: "EnableImageTypes", value: "Primary"),
    URLQueryItem(name: "IncludeItemTypes", value: "MusicAlbum"),
    URLQueryItem(name: "Fields", value: "Genres,Overview,PremiereDate,AlbumArtists,People"),
]

public extension JellyfinClient {
    func albums(limit: Int, startIndex: Int, sortOrder: ItemSortOrder, ascending: Bool, favoriteOnly: Bool = false, artistId: String? = nil, search: String? = nil) async throws -> ([Album], Int) {
        var query = [
            URLQueryItem(name: "SortBy", value: sortOrder.value),
            URLQueryItem(name: "SortOrder", value: ascending ? "Ascending" : "Descending"),
        ]
        
        query += albumQuery
        
        if limit > 0 {
            query.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if startIndex > 0 {
            query.append(URLQueryItem(name: "startIndex", value: String(startIndex)))
        }
        
        if favoriteOnly {
            query.append(URLQueryItem(name: "Filters", value: "IsFavorite"))
        }
        
        if let artistId = artistId {
            query.append(URLQueryItem(name: "AlbumArtistIds", value: artistId))
        }
        if let search = search {
            query.append(URLQueryItem(name: "searchTerm", value: search))
        }
        
        let response = try await request(ClientRequest<JellyfinItemsResponse>(path: "Items", method: "GET", query: query, userPrefix: true))
        
        return (
            response.Items.map(Album.init),
            response.TotalRecordCount
        )
    }
    
    func albums(similarToAlbumId albumId: String) async throws -> [Album] {
        var query = [
            URLQueryItem(name: "Fields", value: "Genres,Overview,PremiereDate"),
            URLQueryItem(name: "limit", value: String(10)),
        ]
        
        query += albumQuery
        
        let response = try await request(ClientRequest<JellyfinItemsResponse>(path: "Items/\(albumId)/Similar", method: "GET", query: query, userId: true))
        return response.Items.map(Album.init)
    }
    
    func album(identifier: String) async throws -> Album {
        let album = try await request(ClientRequest<JellyfinItem>(path: "Items/\(identifier)", method: "GET", query: albumQuery, userPrefix: true))
        return Album(album)
    }
}
