//
//  ItemImage.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import NukeUI
import AFBase

struct ItemImage: View {
    let cover: Item.Cover?
    var cornerRadius: CGFloat = 7
    
    private var placeholder: some View {
        ZStack {
            Image(systemName: "music.note")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 40)
                .foregroundStyle(.gray.opacity(0.5))
                .padding(10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.gray.opacity(0.1))
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    var body: some View {
        if let cover = cover {
            LazyImage(url: cover.url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .clipped()
                } else {
                    placeholder
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            placeholder
        }
    }
}

#Preview {
    ItemImage(cover: nil)
}

#Preview {
    ItemImage(cover: Track.fixture.cover)
}
