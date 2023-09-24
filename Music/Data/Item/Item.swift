//
//  Item.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

@Observable
class Item: Identifiable {
    let id: String
    let name: String
    let sortName: String?
    
    var cover: Cover?
    var favorite: Bool
    
    init(id: String, name: String, sortName: String?, cover: Cover? = nil, favorite: Bool) {
        self.id = id
        self.name = name
        self.sortName = sortName
        self.cover = cover
        self.favorite = favorite
    }
    
    func setFavorite(favorite: Bool) async throws {
        try await JellyfinClient.shared.setFavorite(itemId: id, favorite: favorite)
        self.favorite = true
    }
    
    class Cover: Codable {
        let type: CoverType
        var url: URL
        
        init(type: CoverType, url: URL) {
            self.type = type
            self.url = url
        }
        
        func setSize(_ size: Int) -> Self {
            if type == .jellyfin {
                url = url.appending(queryItems: [
                    URLQueryItem(name: "fillHeight", value: String(size)),
                    URLQueryItem(name: "fillWidth", value: String(size)),
                ])
            }
            
            return self
        }
        
        enum CoverType: Codable {
            case jellyfin
            case local
            case remote
        }
    }
    struct ReducedArtist: Codable {
        let id: String
        let name: String
    }
}
