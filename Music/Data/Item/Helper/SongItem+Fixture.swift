//
//  SongItem+Fixture.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

extension SongItem {
    static let fixture = SongItem(
        // id: "fixture",
        id: "2f4456f908e6fdb022c31884a30c4fd1",
        name: "Panic Station",
        cover: ItemCover(type: .remote, url: URL(string: "https://i.discogs.com/5jht64qo-yxm2ShGhAPrph06N_UUOHmR6MuQx4T2l4A/rs:fit/g:sm/q:90/h:600/w:600/czM6Ly9kaXNjb2dz/LWRhdGFiYXNlLWlt/YWdlcy9SLTM5MjUz/MjUtMTM3MjY3OTcz/OC03MTMzLmpwZWc.jpeg")!),
        index: 3,
        playCount: 9,
        lufs: nil,
        releaseDate: Date(), 
        album: Album(id: "fixture", name: "The 2nd Law", artists: [ItemArtist(id: "fixture", name: "Muse")]),
        artists: [ItemArtist(id: "fixture", name: "Muse")],
        downloaded: false,
        favorite: true)
}
