//
//  Artist.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation

/// Artist that has made a track or album
public class Artist: Item {
    /// Description of the artist
    public let overview: String?
    
    public init(id: String, name: String, cover: Cover? = nil, favorite: Bool, overview: String?) {
        self.overview = overview
        super.init(id: id, type: .artist, name: name, cover: cover, favorite: favorite)
    }
    
    public enum CodingKeys: String, CodingKey {
        case overview
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview)
        
        try super.init(from: decoder)
    }
}
