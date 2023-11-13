//
//  AlbumContextMenuModifier.swift
//  Music
//
//  Created by Rasmus Krämer on 17.10.23.
//

import SwiftUI
import MusicKit

struct AlbumContextMenuModifier: ViewModifier {
    @Environment(\.libraryDataProvider) var dataProvider
    @Environment(\.libraryOnline) var libraryOnline
    
    let album: Album
    
    // this prevents the album from fetching its offline status prematurely
    @State var showDownloadButton = false
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button {
                    Task {
                        try? await album.setFavorite(favorite: !album.favorite)
                    }
                } label: {
                    Label("favorite", systemImage: album.favorite ? "heart.fill" : "heart")
                }
                Button {
                    Task {
                        try? await album.startInstantMix()
                    }
                } label: {
                    Label("queue.mix", systemImage: "compass.drawing")
                }
                .disabled(!libraryOnline)
                
                Divider()
                
                NavigationLink(destination: AlbumView(album: album)) {
                    Label("album.view", systemImage: "square.stack")
                }
                if let first = album.artists.first {
                    NavigationLink(destination: ArtistLoadView(artistId: first.id)) {
                        Label("artist.view", systemImage: "music.mic")
                    }
                    .disabled(!dataProvider.supportsArtistLookup)
                }
                
                Divider()
                
                if showDownloadButton {
                    if album.offline == .none {
                        Button {
                            Task {
                                try! await OfflineManager.shared.downloadAlbum(album)
                            }
                        } label: {
                            Label("download.download", systemImage: "arrow.down")
                        }
                    } else if album.offline == .downloaded {
                        Button {
                            try! OfflineManager.shared.deleteOfflineAlbum(albumId: album.id)
                        } label: {
                            Label("download.remove", systemImage: "xmark")
                        }
                    }
                }
            } preview: {
                VStack(alignment: .leading) {
                    ItemImage(cover: album.cover)
                        .padding(.bottom, 10)
                    
                    Text(album.name)
                    if !album.artists.isEmpty {
                        Text(album.artists.map { $0.name }.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 250)
                .padding()
                .background(.ultraThickMaterial)
                .onAppear {
                    showDownloadButton = true
                }
            }
    }
}

#Preview {
    Text(":)")
        .modifier(AlbumContextMenuModifier(album: Album.fixture))
}
