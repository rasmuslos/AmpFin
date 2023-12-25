//
//  NavigationRoot+Navigation.swift
//  iOS
//
//  Created by Rasmus Krämer on 21.11.23.
//

import Foundation

extension NavigationRoot {
    static let navigateNotification = NSNotification.Name("io.rfk.ampfin.navigation")
    
    static let navigateAlbumNotification = NSNotification.Name("io.rfk.ampfin.navigation.album")
    static let navigateArtistNotification = NSNotification.Name("io.rfk.ampfin.navigation.artist")
}
