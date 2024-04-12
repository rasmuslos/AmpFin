//
//  NavigationRoot+Navigation.swift
//  iOS
//
//  Created by Rasmus Krämer on 21.11.23.
//

import Foundation

struct Navigation {
    static let navigateNotification = NSNotification.Name("io.rfk.ampfin.navigation")
    
    static let navigateAlbumNotification = NSNotification.Name("io.rfk.ampfin.navigation.album")
    static let navigateArtistNotification = NSNotification.Name("io.rfk.ampfin.navigation.artist")
}

extension Navigation {
    enum DataProvider: Hashable {
        case online
        case offline
    }
    
    struct AlbumLoadDestination: Hashable {
        let albumId: String
        var provider: DataProvider? = nil
    }
    
    struct ArtistLoadDestination: Hashable {
        let artistId: String
    }
}
