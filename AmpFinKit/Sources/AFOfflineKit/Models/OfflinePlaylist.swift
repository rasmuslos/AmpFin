//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import SwiftData

@Model
class OfflinePlaylist: OfflineParent {
    public let id: String
    public let name: String
    
    public var favorite: Bool
    public var duration: Double
    
    let childrenIds: [String]
    
    init(id: String, name: String, favorite: Bool, duration: Double, childrenIds: [String]) {
        self.id = id
        self.name = name
        self.favorite = favorite
        self.duration = duration
        self.childrenIds = childrenIds
    }
}
