//
//  NowPlayingBar+ContextMenu.swift
//  iOS
//
//  Created by Rasmus Krämer on 16.03.24.
//

import SwiftUI
import AFBase
import AFPlayback

extension NowPlaying {
    struct ContextMenuModifier: ViewModifier {
        let track: Track
        @Binding var animateForwards: Bool
        
        @State private var addToPlaylistSheetPresented = false
        
        func body(content: Content) -> some View {
            content
                .contextMenu {
                    Button {
                        Task {
                            await track.setFavorite(favorite: !track.favorite)
                        }
                    } label: {
                        Label("favorite", systemImage: track.favorite ? "heart.fill" : "heart")
                    }
                    
                    Button {
                        Task {
                            try? await track.startInstantMix()
                        }
                    } label: {
                        Label("queue.mix", systemImage: "compass.drawing")
                    }
                    .disabled(!JellyfinClient.shared.online)
                    
                    Button {
                        addToPlaylistSheetPresented.toggle()
                    } label: {
                        Label("playlist.add", systemImage: "plus")
                    }
                    .disabled(!JellyfinClient.shared.online)
                    
                    Divider()
                    
                    // why is SwiftUI so stupid?
                    Button(action: {
                        Navigation.navigate(albumId: track.album.id)
                    }) {
                        Label("album.view", systemImage: "square.stack")
                        
                        if let albumName = track.album.name {
                            Text(albumName)
                        }
                    }
                    
                    if let artistId = track.artists.first?.id, let artistName = track.artists.first?.name {
                        Button(action: {
                            Navigation.navigate(artistId: artistId)
                        }) {
                            Label("artist.view", systemImage: "music.mic")
                            Text(artistName)
                        }
                    }
                    
                    Divider()
                    
                    Button {
                        AudioPlayer.current.shuffled = !AudioPlayer.current.shuffled
                    } label: {
                        if AudioPlayer.current.shuffled {
#if targetEnvironment(macCatalyst)
                            Toggle("shuffle", isOn: .constant(true))
#else
                            Label("shuffle", systemImage: "checkmark")
#endif
                        } else {
                            Label("shuffle", systemImage: "shuffle")
                        }
                    }
                    
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
                    
                    Button {
                        AudioPlayer.current.stopPlayback()
                    } label: {
                        Label("playback.stop", systemImage: "stop.circle")
                    }
                    
                    if AudioPlayer.current.source == .jellyfinRemote {
                        Button {
                            AudioPlayer.current.destroy()
                        } label: {
                            Label("remote.disconnect", systemImage: "xmark")
                        }
                    }
                } preview: {
                    VStack(alignment: .leading) {
                        ItemImage(cover: track.cover)
                            .padding(.bottom, 10)
                        
                        Text(track.name)
                        
                        if let artistName = track.artistName {
                            Text(artistName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 250)
                    .padding()
                    .background(.ultraThickMaterial)
                }
                .sheet(isPresented: $addToPlaylistSheetPresented) {
                    PlaylistAddSheet(track: track)
                }
        }
    }
}
