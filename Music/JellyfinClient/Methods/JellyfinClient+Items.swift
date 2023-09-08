//
//  JellyfinClient+Items.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

// MARK: Get all items

extension JellyfinClient {
    func getAllSongs(sortOrder: ItemSortOrder, ascending: Bool) async throws -> [SongItem] {
        let response = try await request(ClientRequest<SongsItemResponse>(path: "Items", method: "GET", query: [
            URLQueryItem(name: "SortBy", value: sortOrder.rawValue),
            URLQueryItem(name: "SortOrder", value: ascending ? "Ascending" : "Descending"),
            URLQueryItem(name: "IncludeItemTypes", value: "Audio"),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
            URLQueryItem(name: "Fields", value: "AudioInfo,ParentId"),
        ]))
        
        return response.Items.enumerated().map { SongItem.convertFromJellyfin($1, fallbackIndex: $0) }
    }
}

// MARK: Get albums

extension JellyfinClient {
    func getAlbums(limit: Int, sortOrder: ItemSortOrder, ascending: Bool) async throws -> [AlbumItem] {
        var query = [
            URLQueryItem(name: "SortBy", value: sortOrder.rawValue),
            URLQueryItem(name: "SortOrder", value: ascending ? "Ascending" : "Descending"),
            URLQueryItem(name: "IncludeItemTypes", value: "MusicAlbum"),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
            URLQueryItem(name: "Fields", value: "Genres,Overview,PremiereDate"),
        ]
        
        if(limit > 0) {
            query.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        
        let response = try await request(ClientRequest<AlbumItemsResponse>(path: "Items", method: "GET", query: query))
        return response.Items.map { AlbumItem.convertFromJellyfin($0) }
    }
}

// MARK: Get album items

extension JellyfinClient {
    func getAlbumItems(id: String) async throws -> [SongItem] {
        let response = try await request(ClientRequest<SongsItemResponse>(path: "Items", method: "GET", query: [
            URLQueryItem(name: "SortBy", value: "ParentIndexNumber,IndexNumber,SortName"),
            URLQueryItem(name: "SortOrder", value: "Ascending"),
            URLQueryItem(name: "IncludeItemTypes", value: "Audio"),
            URLQueryItem(name: "ParentId", value: id),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
            URLQueryItem(name: "Fields", value: "AudioInfo,ParentId"),
        ]))
        
        return response.Items.enumerated().map { SongItem.convertFromJellyfin($1, fallbackIndex: $0) }
    }
}

// MARK: Lyrics

extension JellyfinClient {
    func getLyrics(itemId: String) async throws -> SongItem.Lyrics {
        let userId = UserDefaults.standard.string(forKey: "userId")!
        let response = try await request(ClientRequest<LyricsResponse>(path: "/Users/\(userId)/Items/\(itemId)/Lyrics", method: "GET"))
        
        var lyrics: SongItem.Lyrics = [
            0: nil,
        ]
        response.Lyrics.forEach { element in
            let start = Double(element.Start) / 10_000_000
            var text: String? = element.Text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if text == "" {
                text = nil
            }
            lyrics[start] = text
        }
        
        return lyrics
    }
}

// MARK: Item sorting

extension JellyfinClient {
    enum ItemSortOrder: String, CaseIterable {
        case name = "Name"
        case album = "Album,SortName"
        case albumArtist = "AlbumArtist,Album,SortName"
        case artist = "Artist,Album,SortName"
        case added = "DateCreated,SortName"
        case plays = "PlayCount,SortName"
        case released = "PremiereDate,AlbumArtist,Album,SortName"
        case runtime = "Runtime,AlbumArtist,Album,SortName"
    }
}
