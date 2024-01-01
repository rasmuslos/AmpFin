//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 01.01.24.
//

import Foundation

extension JellyfinClient {
    struct PlaylistItemsResponse: Codable {
        let Items: [JellyfinPlaylist]
    }
    
    struct JellyfinPlaylist: Codable {
        let Id: String
        let Name: String
        
        let ChildCount: Int
        let RunTimeTicks: UInt64
        
        let UserData: UserData
        let ImageTags: ImageTags
    }
}
