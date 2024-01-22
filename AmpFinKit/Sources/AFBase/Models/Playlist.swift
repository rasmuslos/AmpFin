//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 01.01.24.
//

import Foundation

public class Playlist: Item {
    public var duration: Double
    public var trackCount: Int
    
    public init(id: String, name: String, cover: Cover? = nil, favorite: Bool, duration: Double, trackCount: Int) {
        self.duration = duration
        self.trackCount = trackCount
        
        super.init(id: id, type: .playlist, name: name, cover: cover, favorite: favorite)
    }
    
    public enum CodingKeys: String, CodingKey {
        case duration
        case trackCount
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.duration = try container.decode(Double.self, forKey: .duration)
        self.trackCount = try container.decode(Int.self, forKey: .trackCount)
        
        try super.init(from: decoder)
    }
}
