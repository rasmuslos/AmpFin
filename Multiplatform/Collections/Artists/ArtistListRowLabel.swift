//
//  ArtistListRowLabel.swift
//  Multiplatform
//
//  Created by Gnattu OC on 6/1/24.
//

import SwiftUI
import AmpFinKit

struct ArtistListRowLabel: View {
    let artist: Artist

    var body: some View {
        HStack(spacing: 0) {
            ItemImage(cover: artist.cover)
                .frame(width: 44)
                .clipShape(.rect(cornerRadius: .infinity))
                .padding(.trailing, 8)
            
            Text(artist.name)
        }
    }
}
