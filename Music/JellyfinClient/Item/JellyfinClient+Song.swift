//
//  JellyfinClient+Song.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

extension JellyfinClient {
    struct SongsItemResponse: Codable {
        let Items: [JellyfinSongItem]
    }
    
    struct JellyfinSongItem: Codable {
        let Name: String
        let Id: String
        
        let PremiereDate: String?
        let IndexNumber: Int?
        
        let UserData: UserData
        let ArtistItems: [JellyfinArtist]
        
        let Album: String
        let AlbumId: String
        let AlbumArtists: [JellyfinArtist]
        
        let ImageTags: ImageTags
        
        let LUFS: Float?
    }
}
