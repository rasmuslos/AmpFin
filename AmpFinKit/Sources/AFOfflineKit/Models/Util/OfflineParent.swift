//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import AFBaseKit

protocol OfflineParent {
    var childrenIds: [String] { get }
}

extension OfflineParent {
    public var trackCount: Int {
        childrenIds.count
    }
}
