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
                
                Divider()
                
                if showDownloadButton {
                    if album.offline == .none {
                        Button {
                            Task {
                                try! await OfflineManager.shared.downloadAlbum(album)
                            }
                        } label: {
                            Label("Download", systemImage: "arrow.down")
                        }
                    } else if album.offline == .downloaded, let offlineAlbum = OfflineManager.shared.getOfflineAlbum(albumId: album.id) {
                        Button {
                            try! OfflineManager.shared.deleteOfflineAlbum(offlineAlbum)
                        } label: {
                            Label("Remove download", systemImage: "xmark")
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
