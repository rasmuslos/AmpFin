//
//  JellyfinClient+Artist.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation

extension JellyfinClient {
    struct ArtistItemsResponse: Codable {
        let Items: [JellyfinFullArtist]
        let TotalRecordCount: Int
    }
    
    struct JellyfinFullArtist: Codable {
        let Id: String
        let Name: String
        let SortName: String?
        let Overview: String?
        
        let UserData: UserData
        let ImageTags: ImageTags
    }
}
