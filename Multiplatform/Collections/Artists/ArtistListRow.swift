//
//  ArtistListItem.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI
import AmpFinKit

internal struct ArtistListRow: View {
    let artist: Artist

    var body: some View {
        NavigationLink(value: artist) {
            HStack(spacing: 0) {
                ItemImage(cover: artist.cover)
                    .frame(width: 44)
                    .clipShape(.rect(cornerRadius: .infinity))
                    .padding(.trailing, 8)
                
                Text(artist.name)
            }
        }
    }
}

internal extension ArtistListRow {
    typealias Expand = (() -> Void)
    
    // NavigationLink cannot be disabled by allowHitsTesting, make a non-link version for placeholder
    static let placeholder: some View = HStack {
        ItemImage(cover: nil)
            .clipShape(RoundedRectangle(cornerRadius: .infinity))
            .frame(width: 44)
            .padding(.trailing, 8)
        
        Text("placeholder")
    }.redacted(reason: .placeholder)
}
