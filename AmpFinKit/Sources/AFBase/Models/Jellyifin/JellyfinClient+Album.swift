//
//  JellyfinClient+Album.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

extension JellyfinClient {
    struct AlbumItemsResponse: Codable {
        let Items: [JellyfinAlbum]
    }
    
    struct JellyfinAlbum: Codable {
        let Id: String
        let Name: String
        let SortName: String?
        
        let Overview: String?
        let Genres: [String]?
        
        let PremiereDate: String?
        let AlbumArtists: [JellyfinArtist]
        
        let UserData: UserData
        let ImageTags: ImageTags
    }
}
