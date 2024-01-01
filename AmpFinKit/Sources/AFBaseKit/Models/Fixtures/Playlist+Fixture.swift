//
//  File.swift
//
//
//  Created by Rasmus Krämer on 01.01.24.
//

import Foundation

extension Playlist {
    public static let fixture = Playlist(
        id: "fixture",
        name: "🌿",
        cover: Item.Cover(
            type: .mock,
            url:  URL(string: "https://i.discogs.com/5jht64qo-yxm2ShGhAPrph06N_UUOHmR6MuQx4T2l4A/rs:fit/g:sm/q:90/h:600/w:600/czM6Ly9kaXNjb2dz/LWRhdGFiYXNlLWlt/YWdlcy9SLTM5MjUz/MjUtMTM3MjY3OTcz/OC03MTMzLmpwZWc.jpeg")!),
        favorite: true,
        duration: 1000,
        trackCount: 10)
}
