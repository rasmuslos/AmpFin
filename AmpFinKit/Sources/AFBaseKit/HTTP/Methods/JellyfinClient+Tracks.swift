//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation

public extension JellyfinClient {
    func getTrack(id: String) async throws -> Track {
        let track = try await request(ClientRequest<JellyfinTrackItem>(path: "Items/\(id)", method: "GET", userPrefix: true))
        return Track.convertFromJellyfin(track)
    }
    
    // MARK: Get Tracks
    
    /// Get all tracks from all libraries and albums
    func getTracks(limit: Int, sortOrder: ItemSortOrder, ascending: Bool, favorite: Bool) async throws -> [Track] {
        var query = [
            URLQueryItem(name: "SortBy", value: sortOrder.rawValue),
            URLQueryItem(name: "SortOrder", value: ascending ? "Ascending" : "Descending"),
            URLQueryItem(name: "IncludeItemTypes", value: "Audio"),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
            URLQueryItem(name: "Fields", value: "AudioInfo,ParentId"),
        ]
        
        if limit > 0 {
            query.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if favorite {
            query.append(URLQueryItem(name: "Filters", value: "IsFavorite"))
        }
        
        let response = try await request(ClientRequest<TracksItemResponse>(path: "Items", method: "GET", query: query, userPrefix: true))
        return response.Items.enumerated().map { Track.convertFromJellyfin($1, fallbackIndex: $0) }
    }
    
    /// Get all tracks that are children of the specified album
    func getTracks(albumId: String) async throws -> [Track] {
        let response = try await request(ClientRequest<TracksItemResponse>(path: "Items", method: "GET", query: [
            URLQueryItem(name: "SortBy", value: "ParentIndexNumber,IndexNumber,SortName"),
            URLQueryItem(name: "SortOrder", value: "Ascending"),
            URLQueryItem(name: "IncludeItemTypes", value: "Audio"),
            URLQueryItem(name: "ParentId", value: albumId),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
            URLQueryItem(name: "Fields", value: "AudioInfo,ParentId"),
        ], userPrefix: true))
        
        return response.Items.enumerated().map { Track.convertFromJellyfin($1, fallbackIndex: $0) }
    }
    
    /// Get all tracks (limited to 20) matching the query
    func getTracks(query: String) async throws -> [Track] {
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
    
    /// Get instant mix tracks
    func getTracks(instantMixBaseId: String) async throws -> [Track] {
        let response = try await request(ClientRequest<TracksItemResponse>(path: "Items/\(instantMixBaseId)/InstantMix", method: "GET", query: [
            URLQueryItem(name: "limit", value: "200"),
        ], userId: true))
        
        return response.Items.enumerated().map { Track.convertFromJellyfin($1, fallbackIndex: $0) }
    }
    
    // MARK: Other
    
    /// Get a track by its ID
    func getTrack(trackId: String) async -> Track? {
        if let album = try? await request(ClientRequest<JellyfinTrackItem>(path: "Items/\(trackId)", method: "GET", query: [
            URLQueryItem(name: "IncludeItemTypes", value: "Audio"),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
            URLQueryItem(name: "Fields", value: "AudioInfo,ParentId"),
        ], userPrefix: true)) {
            return Track.convertFromJellyfin(album)
        }
        
        return nil
    }
    
    /// Get the lyrics of a track
    func getLyrics(trackId: String) async throws -> Track.Lyrics {
        let response = try await request(ClientRequest<LyricsResponse>(path: "Items/\(trackId)/Lyrics", method: "GET", userPrefix: true))
        var lyrics: Track.Lyrics = [0: nil]
        
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
