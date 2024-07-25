//
//  IntentHandler.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 06.01.24.
//

import Intents
import AFFoundation
import AFExtension

final internal class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any? {
        self
    }
    
    func resolveMediaItems(mediaSearch: INMediaSearch) async throws -> [INMediaItem] {
        guard let primaryName = mediaSearch.mediaName ?? mediaSearch.albumName ?? mediaSearch.artistName else {
            throw SearchError.unsupportedMediaType
        }
        
        let performOfflineSearch = mediaSearch.reference == .my
        
        var results = [Item]()
        let unknownType = mediaSearch.mediaType == .music || mediaSearch.mediaType == .unknown
        
        if !unknownType && !(mediaSearch.mediaType == .album || mediaSearch.mediaType == .artist || mediaSearch.mediaType == .playlist || mediaSearch.mediaType == .song) {
            throw SearchError.unsupportedMediaType
        }
        
        if mediaSearch.mediaType == .album || unknownType {
            if let albums = try? await MediaResolver.shared.search(albumName: primaryName, artistName: mediaSearch.artistName, runOffline: performOfflineSearch) {
                results += albums
            }
        }
        if mediaSearch.mediaType == .artist || unknownType {
            if let artists = try? await MediaResolver.shared.search(artistName: primaryName, runOffline: performOfflineSearch) {
                results += artists
            }
        }
        if mediaSearch.mediaType == .playlist || unknownType {
            if let playlists = try? await MediaResolver.shared.search(playlistName: primaryName, runOffline: performOfflineSearch) {
                results += playlists
            }
        }
        if mediaSearch.mediaType == .song || unknownType {
            if let tracks = try? await MediaResolver.shared.search(trackName: primaryName, albumName: mediaSearch.albumName, artistName: mediaSearch.artistName, runOffline: performOfflineSearch) {
                results += tracks
            }
        }
        
        guard !results.isEmpty else {
            throw SearchError.notFound
        }
        
        results.sort { $0.name.levenshteinDistanceScore(to: primaryName) > $1.name.levenshteinDistanceScore(to: primaryName) }
        
        return await MediaResolver.shared.convert(items: results)
    }
    
    enum SearchError: Error {
        case notFound
        case unsupportedMediaType
    }
}
