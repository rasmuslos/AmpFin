//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import AFFoundation

internal protocol OfflineParent {
    var id: String { get }
    var childrenIdentifiers: [String] { get set }
}

internal extension OfflineParent {
    var trackCount: Int {
        childrenIdentifiers.count
    }
}
