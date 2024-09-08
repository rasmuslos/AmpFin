//
//  NowPlayingBar+ContextMenu.swift
//  iOS
//
//  Created by Rasmus Krämer on 16.03.24.
//

import SwiftUI
import AmpFinKit
import AFPlayback

internal extension NowPlaying {
    struct ContextMenuModifier: ViewModifier {
        @Environment(NowPlaying.ViewModel.self) private var viewModel
        
        let track: Track
        
        @State private var addToPlaylistSheetPresented = false
        
        func body(content: Content) -> some View {
            content
                .contextMenu {
                    Button {
                        Task {
                            try? await track.startInstantMix()
                        }
                    } label: {
                        Label("queue.mix", systemImage: "compass.drawing")
                    }
                    .disabled(!JellyfinClient.shared.online)
                    
                    Divider()
                    
                    Button {
                        track.favorite.toggle()
                    } label: {
                        Label("favorite", systemImage: track.favorite ? "star.fill" : "star")
                    }
                    
                    Button {
                        addToPlaylistSheetPresented.toggle()
                    } label: {
                        Label("playlist.add", systemImage: "plus")
                    }
                    .disabled(!JellyfinClient.shared.online)
                    
                    Divider()
                    
                    Button(action: { Navigation.navigate(albumId: track.album.id) }) {
                        Label("album.view", systemImage: "square.stack")
                    }
                    
                    if let artistId = track.artists.first?.id {
                        Button(action: { Navigation.navigate(artistId: artistId) }) {
                            Label("artist.view", systemImage: "music.mic")
                        }
                    }
                    
                    Divider()
                    
                    Toggle("shuffle", systemImage: "shuffle", isOn: .init(get: { viewModel.shuffled }, set: { AudioPlayer.current.shuffled = $0 }))
                    
                    Menu {
                        ForEach(RepeatMode.allCases.filter { AudioPlayer.current.infiniteQueue != nil || $0 != .infinite }) { repeatMode in
                            Toggle(isOn: .init(get: { viewModel.repeatMode == repeatMode }, set: { _ in AudioPlayer.current.repeatMode = repeatMode })) {
                                switch repeatMode {
                                    case .none:
                                        Label("repeat.none", systemImage: "slash.circle")
                                    case .queue:
                                        Label("repeat.queue", systemImage: "repeat")
                                    case .track:
                                        Label("repeat.track", systemImage: "repeat.1")
                                    case .infinite:
                                        Label("repeat.infinite", systemImage: "infinity")
                                }
                            }
                        }
                    } label: {
                        Label("repeat", systemImage: "repeat")
                    }
                    
                    Divider()
                    
                    Button {
                        AudioPlayer.current.rewind()
                    } label: {
                        Label("playback.back", systemImage: "backward")
                    }
                    
                    Button {
                        AudioPlayer.current.advance()
                    } label: {
                        Label("playback.next", systemImage: "forward")
                    }
                    
                    Divider()
                    
                    if AudioPlayer.current.source == .jellyfinRemote {
                        Button {
                            AudioPlayer.current.stopPlayback()
                        } label: {
                            Label("remote.disconnect", systemImage: "xmark")
                        }
                    } else {
                        Button {
                            AudioPlayer.current.stopPlayback()
                        } label: {
                            Label("playback.stop", systemImage: "stop.circle")
                        }
                    }
                } preview: {
                    VStack(alignment: .leading, spacing: 0) {
                        ItemImage(cover: track.cover)
                        
                        Text(track.name)
                            .padding(.top, 16)
                            .padding(.bottom, 2)
                        
                        if let artistName = track.artistName {
                            Text(artistName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 250)
                    .padding(20)
                }
                .sheet(isPresented: $addToPlaylistSheetPresented) {
                    PlaylistAddSheet(track: track)
                }
        }
    }
}
