//
//  ItemImage.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import NukeUI
import AmpFinKit

internal struct ItemImage: View {
    @Environment(\.redactionReasons) private var redactionReasons
    
    let cover: Cover?
    var cornerRadius: CGFloat? = nil
    
    private func placeholder(cornerRadius: CGFloat) -> some View {
        ZStack {
            if !redactionReasons.contains(.placeholder) {
                Image(systemName: "music.note")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 40)
                    .foregroundStyle(.gray.opacity(0.5))
                    .padding(12)
                    .opacity(redactionReasons.isEmpty ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(.gray.opacity(0.1))
        .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
        .contentShape(.hoverMenuInteraction, .rect(cornerRadius: cornerRadius, style: .continuous))
    }
    
    var body: some View {
        GeometryReader { proxy in
            let cornerRadius: CGFloat = cornerRadius ?? proxy.size.width > 140 ? 8 : 6
            
            if let cover {
                LazyImage(url: cover.url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .clipped()
                    } else {
                        placeholder(cornerRadius: cornerRadius)
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(.rect(cornerRadius: cornerRadius))
                .contentShape(.hoverMenuInteraction, .rect(cornerRadius: cornerRadius))
            } else {
                placeholder(cornerRadius: cornerRadius)
            }
        }
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity).aspectRatio(contentMode: .fit)
    }
}

#Preview {
    ItemImage(cover: nil)
}

#Preview {
    ItemImage(cover: nil)
        .redacted(reason: .placeholder)
}

#Preview {
    ItemImage(cover: .fixture)
}
