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
        let track: Track
        @Binding var animateForwards: Bool
        
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
                    
                    Toggle("shuffle", systemImage: "shuffle", isOn: .init(get: { AudioPlayer.current.shuffled }, set: { AudioPlayer.current.shuffled = $0 }))
                    
                    Menu {
                        Button {
                            AudioPlayer.current.repeatMode = .none
                        } label: {
                            Label("repeat.none", systemImage: "slash.circle")
                        }
                        
                        Button {
                            AudioPlayer.current.repeatMode = .queue
                        } label: {
                            Label("repeat.queue", systemImage: "repeat")
                        }
                        
                        Button {
                            AudioPlayer.current.repeatMode = .track
                        } label: {
                            Label("repeat.track", systemImage: "repeat.1")
                        }
                    } label: {
                        Label("repeat", systemImage: "repeat")
                    }
                    
                    Divider()
                    
                    Button {
                        AudioPlayer.current.backToPreviousItem()
                    } label: {
                        Label("playback.back", systemImage: "backward")
                    }
                    
                    Button {
                        animateForwards.toggle()
                        AudioPlayer.current.advanceToNextTrack()
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
