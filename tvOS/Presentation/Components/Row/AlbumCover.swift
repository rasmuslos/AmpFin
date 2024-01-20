//
//  AlbumCover.swift
//  tvOS
//
//  Created by Rasmus Krämer on 19.01.24.
//

import SwiftUI
import AFBaseKit

struct AlbumCover: View {
    let album: Album
    
    @FocusState var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink(destination: Text(album.name)) {
                ItemImage(cover: album.cover)
            }
            .focused($isFocused)
            .buttonStyle(.card)
            .padding(.bottom, 15)
            
            VStack {
                Text(album.name)
                    .lineLimit(1)
                Text(album.artistName)
                    .lineLimit(1)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .offset(y: isFocused ? 25 : 0)
            .animation(.interactiveSpring, value: isFocused)
        }
    }
}

#Preview {
    AlbumCover(album: Album.fixture)
}
