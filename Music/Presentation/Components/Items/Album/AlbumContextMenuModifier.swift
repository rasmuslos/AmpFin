//
//  AlbumContextMenuModifier.swift
//  Music
//
//  Created by Rasmus Krämer on 17.10.23.
//

import SwiftUI

struct AlbumContextMenuModifier: ViewModifier {
    @Environment(\.libraryOnline) var libraryOnline
    
    let album: Album
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button {
                    Task {
                        try? await album.setFavorite(favorite: !album.favorite)
                    }
                } label: {
                    Label("Favorite", systemImage: album.favorite ? "heart.fill" : "heart")
                }
                Button {
                    Task {
                        try? await album.startInstantMix()
                    }
                } label: {
                    Label("Instant mix", systemImage: "compass.drawing")
                }
                
                Divider()
                
                NavigationLink(destination: AlbumView(album: album)) {
                    Label("View album", systemImage: "square.stack")
                }
                if let first = album.artists.first {
                    NavigationLink(destination: ArtistLoadView(artistId: first.id)) {
                        Label("View artist", systemImage: "music.mic")
                    }
                    .disabled(!libraryOnline)
                }
            } preview: {
                VStack(alignment: .leading) {
                    ItemImage(cover: album.cover)
                        .frame(width: 250)
                        .padding(.bottom, 10)
                    
                    Text(album.name)
                    if !album.artists.isEmpty {
                        Text(album.artists.map { $0.name }.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.ultraThickMaterial)
            }
    }
}
