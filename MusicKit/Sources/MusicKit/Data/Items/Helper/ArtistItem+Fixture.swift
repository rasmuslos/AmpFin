//
//  ArtistItem+Fixture.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation

extension Artist {
    public static let fixture = Artist(
        id: "fixture",
        name: "Muse",
        sortName: "muse",
        cover: Item.Cover(
            type: .remote,
            url: URL(string: "https://yt3.ggpht.com/a/AATXAJwmohGo6Tn5DTGNtJmNxsX-lIr1Tmcj9nZO_0w0=s900-c-k-c0xffffffff-no-rj-mo")!),
        favorite: true,
        overview: "")
}
