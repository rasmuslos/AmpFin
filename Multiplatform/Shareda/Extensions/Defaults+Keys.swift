//
//  Defaults+Keys.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 08.04.24.
//

import Foundation
import Defaults
import AFBase

extension Defaults.Keys {
    static let sortAscending = Key("sortAscending", default: false)
    static let sortOrder = Key<JellyfinClient.ItemSortOrder>("sortOrder", default: .added)
    
    static let artistInstantMix = Key("artistInstantMix", default: false)
    static let libraryRandomAlbums = Key("libraryRandomAlbums", default: false)
}
