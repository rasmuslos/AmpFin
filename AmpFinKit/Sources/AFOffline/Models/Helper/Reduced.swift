//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 03.06.24.
//

import Foundation
import AFFoundation

internal extension Track {
    struct OfflineReducedAlbum: Codable {
        let albumIdentifier: String
        let albumName: String?
        
        let albumArtists: [Item.OfflineReducedArtist]
    }
}

internal extension Item {
    struct OfflineReducedArtist: Codable {
        let artistIdentifier: String
        let artistName: String
    }
}
