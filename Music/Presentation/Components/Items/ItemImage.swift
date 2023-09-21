//
//  ItemImage.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import NukeUI

struct ItemImage: View {
    let cover: Item.Cover?
    
    let placeholder: some View = VStack {
        Spacer()
        HStack {
            Spacer()
            Image(systemName: "music.note")
            Spacer()
        }
        Spacer()
    }
        .background(.gray.opacity(0.2))
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 7))
    
    var body: some View {
        if let cover = cover {
            if cover.type == .remote || cover.type == .local {
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
                .clipShape(RoundedRectangle(cornerRadius: 7))
            }
        } else {
            placeholder
        }
    }
}

#Preview {
    ItemImage(cover: Track.fixture.cover)
}
#Preview {
    ItemImage(cover: nil)
}
