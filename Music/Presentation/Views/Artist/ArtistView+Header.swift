//
//  ArtistView+Header.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI

extension ArtistView {
    struct Header: View {
        let artist: Artist
        
        var body: some View {
            VStack {
                ItemImage(cover: artist.cover)
                    .frame(width: 75)
                    .clipShape(RoundedRectangle(cornerRadius: 1000))
                
                Text(artist.name)
                    .padding(.top, 7)
                    .font(.title2)
            }
        }
    }
}
