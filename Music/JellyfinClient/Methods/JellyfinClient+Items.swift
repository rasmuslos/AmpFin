//
//  JellyfinClient+Items.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

// MARK: Get all tracks

extension JellyfinClient {
    func getAllTracks(sortOrder: ItemSortOrder, ascending: Bool) async throws -> [Track] {
        let response = try await request(ClientRequest<TracksItemResponse>(path: "Items", method: "GET", query: [
            URLQueryItem(name: "SortBy", value: sortOrder.rawValue),
            URLQueryItem(name: "SortOrder", value: ascending ? "Ascending" : "Descending"),
            URLQueryItem(name: "IncludeItemTypes", value: "Audio"),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
            URLQueryItem(name: "Fields", value: "AudioInfo,ParentId"),
        ]))
        
        return response.Items.enumerated().map { Track.convertFromJellyfin($1, fallbackIndex: $0) }
    }
}

// MARK: Get albums

extension JellyfinClient {
    func getAlbums(limit: Int, sortOrder: ItemSortOrder, ascending: Bool) async throws -> [Album] {
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
        return response.Items.map(Album.convertFromJellyfin)
    }
}

// MARK: Get album tracks

extension JellyfinClient {
    func getAlbumTracks(id: String) async throws -> [Track] {
        let response = try await request(ClientRequest<TracksItemResponse>(path: "Items", method: "GET", query: [
            URLQueryItem(name: "SortBy", value: "ParentIndexNumber,IndexNumber,SortName"),
            URLQueryItem(name: "SortOrder", value: "Ascending"),
            URLQueryItem(name: "IncludeItemTypes", value: "Audio"),
            URLQueryItem(name: "ParentId", value: id),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
            URLQueryItem(name: "Fields", value: "AudioInfo,ParentId"),
        ], userPrefix: true))
        
        return response.Items.enumerated().map { Track.convertFromJellyfin($1, fallbackIndex: $0) }
    }
}

// MARK: Lyrics

extension JellyfinClient {
    func getLyrics(trackId: String) async throws -> Track.Lyrics {
        let response = try await request(ClientRequest<LyricsResponse>(path: "Items/\(trackId)/Lyrics", method: "GET", userPrefix: true))
        
        var lyrics: Track.Lyrics = [
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

// MARK: Artists

extension JellyfinClient {
    func getArtists(albumOnly: Bool) async throws -> [Artist] {
        let response = try await request(ClientRequest<ArtistItemsResponse>(path: albumOnly ? "Artists/AlbumArtists" : "Artists", method: "GET", query: [
            URLQueryItem(name: "SortBy", value: ItemSortOrder.name.rawValue),
            URLQueryItem(name: "SortOrder", value: "Ascending"),
            // URLQueryItem(name: "Recursive", value: "true"),
        ]))
        
        return response.Items.map(Artist.convertFromJellyfin)
    }
}

// MARK: Get artist albums

extension JellyfinClient {
    func getArtistAlbums(id: String, sortOrder: ItemSortOrder, ascending: Bool) async throws -> [Album] {
        let response = try await request(ClientRequest<AlbumItemsResponse>(path: "Items", method: "GET", query: [
            URLQueryItem(name: "SortBy", value: sortOrder.rawValue),
            URLQueryItem(name: "SortOrder", value: ascending ? "Ascending" : "Descending"),
            URLQueryItem(name: "IncludeItemTypes", value: "MusicAlbum"),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
            URLQueryItem(name: "Fields", value: "Genres,Overview,PremiereDate"),
            URLQueryItem(name: "AlbumArtistIds", value: id),
        ], userPrefix: true))
        
        return response.Items.map(Album.convertFromJellyfin)
    }
}

// MARK: Get artist by id

extension JellyfinClient {
    func getArtistById(_ artistId: String) async throws -> Artist? {
        if let artist = try await request(ClientRequest<JellyfinFullArtist?>(path: "Items/\(artistId)", method: "GET", userPrefix: true)) {
            return Artist.convertFromJellyfin(artist)
        } else {
            return nil
        }
    }
}

// MARK: Get album by id

extension JellyfinClient {
    func getAlbumById(_ albumId: String) async throws -> Album? {
        if let album = try await request(ClientRequest<JellyfinAlbum?>(path: "Items/\(albumId)", method: "GET", query: [
            URLQueryItem(name: "IncludeItemTypes", value: "MusicAlbum"),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
            URLQueryItem(name: "Fields", value: "Genres,Overview,PremiereDate"),
        ], userPrefix: true)) {
            return Album.convertFromJellyfin(album)
        } else {
            return nil
        }
    }
}

// MARK: Search

extension JellyfinClient {
    func searchTracks(query: String) async throws -> [Track] {
        let tracks = try await request(ClientRequest<TracksItemResponse>(path: "Items", method: "GET", query: [
            URLQueryItem(name: "searchTerm", value: query),
            URLQueryItem(name: "Limit", value: "20"),
            URLQueryItem(name: "IncludeItemTypes", value: "Audio"),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
            URLQueryItem(name: "Fields", value: "AudioInfo,ParentId"),
        ], userPrefix: true))
        return tracks.Items.map { Track.convertFromJellyfin($0, fallbackIndex: 0) }
    }
    func searchAlbums(query: String) async throws -> [Album] {
        let tracks = try await request(ClientRequest<AlbumItemsResponse>(path: "Items", method: "GET", query: [
            URLQueryItem(name: "searchTerm", value: query),
            URLQueryItem(name: "Limit", value: "20"),
            URLQueryItem(name: "IncludeItemTypes", value: "MusicAlbum"),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
            URLQueryItem(name: "Fields", value: "Genres,Overview,PremiereDate,AlbumArtists,People"),
        ], userPrefix: true))
        return tracks.Items.map(Album.convertFromJellyfin)
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
