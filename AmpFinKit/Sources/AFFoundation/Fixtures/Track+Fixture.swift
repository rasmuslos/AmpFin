//
//  Track+Fixture.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

public extension Track {
    static let fixture = Track(
        id: "fixture",
        name: "Panic Station",
        cover: .fixture,
        favorite: true,
        album: ReducedAlbum(
            id: "fixture",
            name: "The 2nd Law",
            artists: [
                Item.ReducedArtist(id: "fixture", name: "Muse"),
            ]),
        artists: [
            Item.ReducedArtist(id: "fixture", name: "Muse"),
        ],
        lufs: nil,
        index: Track.Index(index: 3, disk: 1),
        runtime: 144,
        playCount: 9,
        releaseDate: Date())
}
