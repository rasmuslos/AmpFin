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
        NavigationLink {
            ArtistView(artist: artist)
        } label: {
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
    typealias Expand = (() -> Void)
    
    // NavigationLink cannot be disabled by allowHitsTesting, make a non-link version for placeholder
    static let placeholder: some View = HStack {
        ItemImage(cover: nil)
            .clipShape(RoundedRectangle(cornerRadius: 1000))
            .frame(width: 45)
        
        Text("placeholder")
            .padding(.horizontal, 5)
    }.redacted(reason: .placeholder)
}
