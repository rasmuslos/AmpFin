//
//  ArtistListItem.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI
import AFBase

struct ArtistListRow: View {
    let artist: Artist
    
    var body: some View {
        NavigationLink(destination: ArtistView(artist: artist)) {
            HStack {
                ItemImage(cover: artist.cover)
                    .clipShape(RoundedRectangle(cornerRadius: 1000))
                    .frame(width: 45)
                
                Text(artist.name)
                    .padding(.horizontal, 5)
            }
        }
    }
}

extension ArtistListRow {
    static let placeholder: some View = ArtistListRow (
        artist: .init(
            id: "placeholder",
            name: "Placeholder",
            cover: nil,
            favorite: false,
            overview: nil)
    ).redacted(reason: .placeholder)
}
