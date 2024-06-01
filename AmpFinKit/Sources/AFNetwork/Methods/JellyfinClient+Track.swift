//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFFoundation

private let trackQuery = [
    URLQueryItem(name: "IncludeItemTypes", value: "Audio"),
    URLQueryItem(name: "Recursive", value: "true"),
    URLQueryItem(name: "ImageTypeLimit", value: "1"),
    URLQueryItem(name: "EnableImageTypes", value: "Primary"),
    URLQueryItem(name: "Fields", value: "AudioInfo,ParentId"),
]

public extension JellyfinClient {
    func tracks(limit: Int, startIndex: Int, sortOrder: ItemSortOrder, ascending: Bool, favoriteOnly: Bool = false, search: String? = nil, coverSize: Cover.CoverSize = .normal) async throws -> ([Track], Int) {
        var query = [
            URLQueryItem(name: "SortBy", value: sortOrder.value),
            URLQueryItem(name: "SortOrder", value: ascending ? "Ascending" : "Descending"),
        ]
        
        query += trackQuery
        
        if limit > 0 {
            query.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if startIndex > 0 {
            query.append(URLQueryItem(name: "startIndex", value: String(startIndex)))
        }
        if favoriteOnly {
            query.append(URLQueryItem(name: "Filters", value: "IsFavorite"))
        }
        if let search = search {
            query.append(URLQueryItem(name: "searchTerm", value: search))
        }
        
        let response = try await request(ClientRequest<JellyfinItemsResponse>(path: "Items", method: "GET", query: query, userPrefix: true))
        
        return (
            response.Items.enumerated().compactMap { Track($1, fallbackIndex: $0, coverSize: coverSize) },
            response.TotalRecordCount
        )
    }
    
    func tracks(instantMixBaseId identifier: String, limit: Int = 200) async throws -> [Track] {
        let response = try await request(ClientRequest<JellyfinItemsResponse>(path: "Items/\(identifier)/InstantMix", method: "GET", query: [
            URLQueryItem(name: "limit", value: String(limit)),
        ], userId: true))
        
        return response.Items.enumerated().compactMap { Track($1, fallbackIndex: $0) }
    }
    
    func tracks(albumId identifier: String) async throws -> [Track] {
        var query = [
            URLQueryItem(name: "SortBy", value: "ParentIndexNumber,IndexNumber,SortName"),
            URLQueryItem(name: "SortOrder", value: "Ascending"),
            URLQueryItem(name: "ParentId", value: identifier),
        ]
        
        query += trackQuery
        
        let response = try await request(ClientRequest<JellyfinItemsResponse>(path: "Items", method: "GET", query: query, userPrefix: true))
        return response.Items.enumerated().compactMap { Track($1, fallbackIndex: $0) }
    }
    
    func tracks(playlistId identifier: String) async throws -> [Track] {
        let response = try await request(ClientRequest<JellyfinItemsResponse>(path: "Playlists/\(identifier)/Items", method: "GET", query: trackQuery, userId: true))
        return response.Items.enumerated().compactMap { Track($1, fallbackIndex: $0) }
    }
    
    func tracks(artistId identifier: String, sortOrder: ItemSortOrder, ascending: Bool, limit: Int = 30) async throws -> [Track] {
        var query = [
            URLQueryItem(name: "SortBy", value: sortOrder.value),
            URLQueryItem(name: "SortOrder", value: ascending ? "Ascending" : "Descending"),
            URLQueryItem(name: "ArtistIds", value: identifier),
            URLQueryItem(name: "Limit", value: String(limit)),
        ]
        
        query += trackQuery
        
        let response = try await request(ClientRequest<JellyfinItemsResponse>(path: "Items", method: "GET", query: query, userPrefix: true))
        return response.Items.enumerated().compactMap { Track($1, fallbackIndex: $0) }
    }
    
    func track(identifier: String) async throws -> Track {
        let item = try await request(ClientRequest<JellyfinItem>(path: "Items/\(identifier)", method: "GET", query: trackQuery, userPrefix: true))
        
        guard let track = Track(item) else {
            throw ClientError.invalidResponse
        }
        
        return track
    }
    
    func lyrics(trackId identifier: String) async throws -> Track.Lyrics {
        let response = try await request(ClientRequest<LyricsResponse>(path: "Audio/\(identifier)/Lyrics", method: "GET"))
        var lyrics: Track.Lyrics = [0: nil]
        
        response.Lyrics.forEach { element in
            let start = Double(element.Start) / 10_000_000
            var text: String? = element.Text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if text == "" {
                text = nil
            }
            
            lyrics[start] = text
        }
        
        if lyrics.count <= 1 {
            throw ClientError.invalidResponse
        }
        
        return lyrics
    }
    
    func mediaInfo(trackId identifier: String) async throws -> Track.MediaInfo {
        let track = try await request(ClientRequest<JellyfinItem>(path: "Items/\(identifier)", method: "GET", userPrefix: true))
        
        guard let mediaStreams = track.MediaStreams, let audioStream = mediaStreams.first(where: { $0.Type == "Audio" }) else {
            throw ClientError.invalidResponse
        }
        
        let lossless: Bool
        
        if let codec = audioStream.Codec?.lowercased(), codec == "flac" || codec == "alac" || codec == "ape" || codec == "wave" || codec.starts(with: "pcm") {
            lossless = true
        } else {
            lossless = false
        }
        
        return .init(codec: audioStream.Codec, lossless: lossless, bitrate: audioStream.BitRate, bitDepth: audioStream.BitDepth, sampleRate: audioStream.SampleRate)
    }
}
