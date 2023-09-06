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
        let Name: String
        let Id: String
        let SortName: String?
        let PremiereDate: String?
        let UserData: UserData
        let ArtistItems: [JellyfinArtist]
        let ImageTags: ImageTags
    }
}
