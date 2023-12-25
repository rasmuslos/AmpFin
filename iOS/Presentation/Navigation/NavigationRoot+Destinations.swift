//
//  NavigationRoot+Destinations.swift
//  iOS
//
//  Created by Rasmus Krämer on 21.11.23.
//

import Foundation

extension NavigationRoot {
    struct AlbumLoadDestination: Hashable {
        let albumId: String
    }
    
    struct ArtistLoadDestination: Hashable {
        let artistId: String
    }
}
