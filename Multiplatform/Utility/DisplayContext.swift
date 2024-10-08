//
//  DisplayContext.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.07.24.
//

import Foundation
import SwiftUI

internal enum DisplayContext: Identifiable, Equatable, Hashable {
    case unknown
    case album
    case artist
    case playlist
    case favorite
    case search
    
    var id: Self {
        self
    }
}

internal extension EnvironmentValues {
    @Entry var displayContext: DisplayContext = .unknown
}
