//
//  Item.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import OSLog

@Observable
public class Item: Codable, Identifiable {
    public let id: String
    public let type: ItemType
    
    public let name: String
    
    public var cover: Cover?
    public var _favorite: Bool
    
    internal init(id: String, type: ItemType, name: String, cover: Cover? = nil, favorite: Bool) {
        self.id = id
        self.type = type
        self.name = name
        self.cover = cover
        self._favorite = favorite
    }
    
    private enum CodingKeys: CodingKey {
        case id
        case type
        case name
        case cover
        case favorite
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(ItemType.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        cover = try container.decodeIfPresent(Cover.self, forKey: .cover)
        _favorite = try container.decode(Bool.self, forKey: .favorite)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(cover, forKey: .cover)
        try container.encode(_favorite, forKey: .favorite)
    }
}

extension Item: Equatable {
    public static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
}

extension Item: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public extension Item {
    struct ReducedArtist: Codable {
        public let id: String
        public let name: String
        
        public init(id: String, name: String) {
            self.id = id
            self.name = name
        }
    }
    
    enum ItemType: Codable, Hashable {
        case album
        case artist
        case track
        case playlist
    }
    
    static let affinityChangedNotification = NSNotification.Name("io.rfk.ampfin.item.affinity")
}

public extension Item {
    var sortName: String {
        var sortName = name.lowercased()
        
        if sortName.starts(with: "a ") {
            sortName = String(sortName.dropFirst(2))
        }
        if sortName.starts(with: "the ") {
            sortName = String(sortName.dropFirst(4))
        }
        
        return sortName
    }
}
