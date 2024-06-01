//
//  File.swift
//
//
//  Created by Rasmus Krämer on 01.01.24.
//

import Foundation

public extension Playlist {
    static let fixture = Playlist(
        id: "fixture",
        name: "Playlist",
        cover: .fixture,
        favorite: true,
        duration: 1000,
        trackCount: 10)
}
