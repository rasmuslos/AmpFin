//
//  AlbumItem+Fixture.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

public extension Album {
    static let fixture = Album(
        id: "fixture",
        name: "The 2nd Law",
        cover: .fixture,
        favorite: true,
        overview: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
        genres: ["Alternative"],
        releaseDate: Date(),
        artists: [
            Item.ReducedArtist(id: "fixture", name: "Muse"),
        ],
        playCount: 9,
        lastPlayed: Date())
}
