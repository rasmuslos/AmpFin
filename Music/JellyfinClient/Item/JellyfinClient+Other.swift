//
//  JellyfinClient+Other.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

extension JellyfinClient {
    struct UserData: Codable {
        let PlayCount: Int
        let IsFavorite: Bool
    }
    
    struct JellyfinArtist: Codable {
        let Id: String
        let Name: String
    }
    
    struct ImageTags: Codable {
        let Primary: String?
    }
}
