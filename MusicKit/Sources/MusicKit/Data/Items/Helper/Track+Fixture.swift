//
//  Track+Fixture.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

extension Track {
    public static let fixture = Track(
        id: "fixture",
        name: "Panic Station",
        sortName: "panic_station",
        cover: Item.Cover(
            type: .remote,
            url:  URL(string: "https://i.discogs.com/5jht64qo-yxm2ShGhAPrph06N_UUOHmR6MuQx4T2l4A/rs:fit/g:sm/q:90/h:600/w:600/czM6Ly9kaXNjb2dz/LWRhdGFiYXNlLWlt/YWdlcy9SLTM5MjUz/MjUtMTM3MjY3OTcz/OC03MTMzLmpwZWc.jpeg")!),
        favorite: true,
        album: ReducedAlbum(
            id: "fixture",
            name: "The 2nd Law",
            artists: [Item.ReducedArtist(id: "fixture", name: "Muse"),]),
        artists: [
            Item.ReducedArtist(id: "fixture", name: "Muse"),
        ],
        lufs: nil,
        index: Track.Index(
            index: 3,
            disk: 1
        ),
        playCount: 9,
        releaseDate: Date())
}
