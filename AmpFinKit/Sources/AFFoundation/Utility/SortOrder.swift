//
//  File.swift
//
//
//  Created by Rasmus Krämer on 15.05.24.
//

import Foundation
import Defaults

public enum ItemSortOrder: CaseIterable, Codable, Defaults.Serializable {
    case name
    case album
    case albumArtist
    case artist
    case added
    case plays
    case lastPlayed
    case released
    case runtime
    case random
}
