//
//  Defaults+Keys.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 08.04.24.
//

import Foundation
import Defaults
import AmpFinKit

internal extension Defaults.Keys {
    static let migratedToNewDatastore = Key("migratedToNewDatastore_n1u3enjoieqgurfjciuqw0ayj", default: false)
    
    // MARK: Sort
    static let sortAscending = Key("sortAscending", default: false)
    static let sortOrder = Key<ItemSortOrder>("sortOrder", default: .added)
    
    // MARK: Navigation
    
    static let searchTab = Key<SearchView.Tab>("searchTab", default: .online)
    static let activeTab = Key<Tabs.Selection>("activeTab", default: .library)
    
    static let sidebarSelection = Key<Sidebar.Selection?>("sidebarSelection")
    static let playlistSectionExpanded = Key("playlistSectionExpanded", default: true)
    
    static func providerExpanded(_ provider: Sidebar.DataProvider) -> Key<Bool> {
        .init("providerExpanded_\(provider.hashValue)", default: true)
    }
    
    // MARK: Spotlight
    
    static let lastSpotlightDonation = Key<Double>("lastSpotlightDonation", default: 0)
    static let lastSpotlightDonationCompletion = Key<Double>("lastSpotlightDonationCompletion", default: 0)
    
    // MARK: Settings
    
    static let artistInstantMix = Key("artistInstantMix", default: false)
    static let libraryRandomAlbums = Key("libraryRandomAlbums", default: false)
}
