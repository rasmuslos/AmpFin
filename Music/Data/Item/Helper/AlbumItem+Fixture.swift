//
//  AlbumItem+Fixture.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

extension AlbumItem {
    static let fixture = AlbumItem(
        id: "fixture",
        name: "The 2nd Law",
        sortName: "00000002nd law",
        releaseDate: Date(),
        artists: [ItemArtist(id: "fixture", name: "Muse")],
        cover: ItemCover(type: .remote, url: URL(string: "https://i.discogs.com/5jht64qo-yxm2ShGhAPrph06N_UUOHmR6MuQx4T2l4A/rs:fit/g:sm/q:90/h:600/w:600/czM6Ly9kaXNjb2dz/LWRhdGFiYXNlLWlt/YWdlcy9SLTM5MjUz/MjUtMTM3MjY3OTcz/OC03MTMzLmpwZWc.jpeg")!),
        downloaded: false,
        favorite: true,
        playCount: 9)
}
