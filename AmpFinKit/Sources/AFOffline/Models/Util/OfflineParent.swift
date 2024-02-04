//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import AFBase

protocol OfflineParent {
    var id: String { get }
    var childrenIds: [String] { get set }
}

extension OfflineParent {
    public var trackCount: Int {
        childrenIds.count
    }
}
