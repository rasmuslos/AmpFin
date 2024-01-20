//
//  ItemImage.swift
//  tvOS
//
//  Created by Rasmus Krämer on 19.01.24.
//

import SwiftUI
import NukeUI
import AFBaseKit

struct ItemImage: View {
    let cover: Item.Cover?
    var cornerRadius: CGFloat = 7
    
    var placeholder: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack(spacing: 0) {
                Spacer()
                Image(systemName: "music.note")
                Spacer()
            }
            Spacer()
        }
        .background(.ultraThickMaterial)
    }
    
    var body: some View {
        Group {
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
            } else {
                placeholder
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    ItemImage(cover: Track.fixture.cover)
}
#Preview {
    ItemImage(cover: nil)
}
