//
//  AlbumGridItem.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AmpFinKit

internal struct AlbumCover: View {
    @Environment(\.redactionReasons) private var redactionReasons
    
    let album: Album
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ItemImage(cover: album.cover)
            
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(album.name)
                        .font(.subheadline)
                        .lineLimit(1)
                    
                    Group {
                        if let artistName = album.artistName {
                            Text(artistName)
                        } else {
                            Text(verbatim: "")
                        }
                    }
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                }
                
                if album.favorite {
                    Spacer(minLength: 4)
                    
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.tint)
                }
            }
            .padding(.top, 8)
        }
        .padding(8)
        .contentShape(.hoverMenuInteraction, .rect(cornerRadius: 12))
        .modifier(AlbumContextMenuModifier(album: album))
        .padding(-8)
    }
}

internal extension AlbumCover {
    static let placeholder: some View = AlbumCover(album: .init(
        id: "placeholder",
        name: "Placeholder",
        cover: nil,
        favorite: false,
        overview: nil,
        genres: [],
        releaseDate: nil,
        artists: [.init(id: "placeholder", name: "Placeholder")],
        playCount: 0,
        lastPlayed: nil)
    ).redacted(reason: .placeholder)
}

#Preview {
    AlbumCover(album: .fixture)
}

#Preview {
    AlbumCover.placeholder
}
