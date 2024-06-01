//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import AFFoundation

protocol OfflineParent {
    var id: String { get }
    var childrenIds: [String] { get set }
}

extension OfflineParent {
    var trackCount: Int {
        childrenIds.count
    }
}
