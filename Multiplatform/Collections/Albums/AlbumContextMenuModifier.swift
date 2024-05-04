//
//  AlbumContextMenuModifier.swift
//  Music
//
//  Created by Rasmus Krämer on 17.10.23.
//

import SwiftUI
import AFBase
import AFOffline
import AFPlayback

struct AlbumContextMenuModifier: ViewModifier {
    @Environment(\.libraryDataProvider) private var dataProvider
    
    let album: Album
    let offlineTracker: ItemOfflineTracker
    
    init(album: Album) {
        self.album = album
        self.offlineTracker = album.offlineTracker
    }
    
    // this prevents the album from fetching its offline status prematurely
    @State private var showDownloadButton = false
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button {
                    Task {
                        AudioPlayer.current.startPlayback(tracks: try await dataProvider.getTracks(albumId: album.id), startIndex: 0, shuffle: false, playbackInfo: .init(container: album))
                    }
                } label: {
                    Label("play", systemImage: "play")
                }
                
                Divider()
                
                Button {
                    Task {
                        await album.setFavorite(favorite: !album.favorite)
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
                .disabled(!JellyfinClient.shared.online)
                
                Divider()
                
                Button {
                    Task {
                        AudioPlayer.current.queueTracks(try await dataProvider.getTracks(albumId: album.id), index: 0, playbackInfo: .init(container: album, queueLocation: .next))
                    }
                } label: {
                    Label("queue.next", systemImage: "text.line.first.and.arrowtriangle.forward")
                }
                
                Button {
                    Task {
                        AudioPlayer.current.queueTracks(try await dataProvider.getTracks(albumId: album.id), index: AudioPlayer.current.queue.count, playbackInfo: .init(container: album, queueLocation: .later))
                    }
                } label: {
                    Label("queue.last", systemImage: "text.line.last.and.arrowtriangle.forward")
                }
                
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
                    let offlineTracker = album.offlineTracker
                    
                    if offlineTracker.status == .none {
                        Button {
                            Task {
                                try! await OfflineManager.shared.download(album: album)
                            }
                        } label: {
                            Label("download", systemImage: "arrow.down")
                        }
                    } else if offlineTracker.status == .downloaded {
                        Button {
                            try! OfflineManager.shared.delete(albumId: album.id)
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
                        Text(album.artistName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 250)
                .padding(20)
                .background(.ultraThickMaterial)
                .onAppear {
                    showDownloadButton = true
                }
            }
    }
}

#Preview {
    Text(verbatim: ":)")
        .modifier(AlbumContextMenuModifier(album: Album.fixture))
}
