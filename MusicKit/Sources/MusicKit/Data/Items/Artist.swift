//
//  Artist.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation

public class Artist: Item {
    public let overview: String?
    
    init(id: String, name: String, sortName: String?, cover: Cover? = nil, favorite: Bool, overview: String?) {
        self.overview = overview
        super.init(id: id, name: name, sortName: sortName, cover: cover, favorite: favorite)
    }
}
