//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 21.05.24.
//

import Foundation
import Defaults

public enum RepeatMode: Int, Identifiable, Equatable, Codable, CaseIterable, _DefaultsSerializable {
    case none = 0
    case track = 1
    case queue = 2
    case infinite = 3
    
    public var id: Int {
        rawValue
    }
}
