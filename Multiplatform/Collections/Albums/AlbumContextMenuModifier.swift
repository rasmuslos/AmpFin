//
//  AlbumContextMenuModifier.swift
//  Music
//
//  Created by Rasmus Krämer on 17.10.23.
//

import SwiftUI
import AmpFinKit
import AFPlayback

struct AlbumContextMenuModifier: ViewModifier {
    @Environment(\.libraryDataProvider) private var dataProvider
    
    let album: Album
    @State private var offlineTracker: ItemOfflineTracker?
    
    // this prevents the album from fetching its offline status prematurely
    @State private var showDownloadButton = false
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button {
                    Task {
                        AudioPlayer.current.startPlayback(tracks: try await dataProvider.tracks(albumId: album.id), startIndex: 0, shuffle: false, playbackInfo: .init(container: album))
                    }
                } label: {
                    Label("play", systemImage: "play")
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
                        AudioPlayer.current.queueTracks(try await dataProvider.tracks(albumId: album.id), index: 0, playbackInfo: .init(container: album, queueLocation: .next))
                    }
                } label: {
                    Label("queue.next", systemImage: "text.line.first.and.arrowtriangle.forward")
                }
                
                Button {
                    Task {
                        AudioPlayer.current.queueTracks(try await dataProvider.tracks(albumId: album.id), index: AudioPlayer.current.queue.count, playbackInfo: .init(container: album, queueLocation: .later))
                    }
                } label: {
                    Label("queue.last", systemImage: "text.line.last.and.arrowtriangle.forward")
                }
                
                Divider()
                
                Button {
                    album.favorite.toggle()
                } label: {
                    Label("favorite", systemImage: album.favorite ? "star.fill" : "star")
                }
                
                Divider()
                
                NavigationLink(value: album) {
                    Label("album.view", systemImage: "square.stack")
                }
                if let first = album.artists.first {
                    NavigationLink(value: .artistLoadDestination(artistId: first.id)) {
                        Label("artist.view", systemImage: "music.mic")
                    }
                    .disabled(!dataProvider.supportsArtistLookup)
                }
                
                Divider()
                    .onAppear {
                        offlineTracker = album.offlineTracker
                    }
                
                if let offlineTracker = offlineTracker {
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
                VStack(alignment: .leading, spacing: 0) {
                    ItemImage(cover: album.cover)
                    
                    Text(album.name)
                        .padding(.top, 16)
                        .padding(.bottom, 2)
                    
                    if let artistName = album.artistName {
                        Text(artistName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 250)
                .padding(20)
            }
    }
}

#Preview {
    Text(verbatim: ":)")
        .modifier(AlbumContextMenuModifier(album: .fixture))
}
