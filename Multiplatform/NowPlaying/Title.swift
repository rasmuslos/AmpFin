//
//  NowPlayingView+Title.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AmpFinKit
import AFPlayback

internal extension NowPlaying {
    // MARK: Cover
    
    struct LargeTitle: View {
        let track: Track
        let currentTab: Tab
        let namespace: Namespace.ID
        
        var body: some View {
            Spacer()
            
            ItemImage(cover: track.cover)
                .id(track.id)
                .shadow(radius: 20)
                .scaleEffect(AudioPlayer.current.playing ? 1 : 0.8)
                .animation(.spring(duration: 0.3, bounce: 0.6), value: AudioPlayer.current.playing)
                .matchedGeometryEffect(id: "image", in: namespace, properties: .frame, anchor: .topLeading, isSource: currentTab == .cover)
            
            Spacer()
            
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.name)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                        .matchedGeometryEffect(id: "title", in: namespace, properties: .frame, anchor: .top)
                    
                    ArtistsMenu(track: track)
                        .font(.body)
                        .matchedGeometryEffect(id: "artist", in: namespace, properties: .frame, anchor: .top)
                }
                
                Spacer(minLength: 12)
                
                FavoriteButton(track: track)
                    .matchedGeometryEffect(id: "menu", in: namespace, properties: .frame, anchor: .top)
            }
        }
    }
    
    // MARK: Small Title
    
    struct SmallTitle: View {
        let track: Track
        let namespace: Namespace.ID
        
        @Binding var currentTab: Tab
        
        var body: some View {
            HStack(spacing: 8) {
                ItemImage(cover: track.cover)
                    .shadow(radius: 10)
                    .frame(width: 72, height: 72)
                    .matchedGeometryEffect(id: "image", in: namespace, properties: .frame, anchor: .topLeading, isSource: currentTab != .cover)
                    .onTapGesture {
                        withAnimation {
                            currentTab = .cover
                        }
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.name)
                        .lineLimit(1)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .matchedGeometryEffect(id: "title", in: namespace, properties: .frame, anchor: .bottom)
                    
                    ArtistsMenu(track: track)
                        .font(.body)
                        .matchedGeometryEffect(id: "artist", in: namespace, properties: .frame, anchor: .bottom)
                }
                
                Spacer()
                
                FavoriteButton(track: track)
                    .matchedGeometryEffect(id: "menu", in: namespace, properties: .frame, anchor: .bottom)
            }
            .contentShape(.rect)
        }
    }
}

private extension NowPlaying {
    struct FavoriteButton: View {
        let track: Track
        
        var body: some View {
            if AudioPlayer.current.source == .local {
                Button {
                    track.favorite.toggle()
                } label: {
                    Label("favorite", systemImage: "star")
                        .symbolVariant(.circle.fill)
                        .symbolRenderingMode(.palette)
                        .symbolEffect(track.favorite ? .bounce.byLayer.down : .bounce.byLayer.up, options: .speed(0.4), value: track.favorite)
                        .labelStyle(.iconOnly)
                        .font(.title)
                        .foregroundStyle(.white.opacity(track.favorite ? 0.8 : 0.4), .white.opacity(track.favorite ? 0.4 : 0.2))
                        .symbolRenderingMode(.palette)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .modifier(HoverEffectModifier())
            }
        }
    }
    
    struct ArtistsMenu: View {
        let track: Track
        
        @State private var addToPlaylistSheetPresented = false
        
        var body: some View {
            Menu {
                Button(action: { Navigation.navigate(albumId: track.album.id) }) {
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
                
                if let playbackInfo = AudioPlayer.current.playbackInfo, let playlist = playbackInfo.container as? Playlist {
                    Button(action: {
                        Navigation.navigate(playlistId: playlist.id)
                    }) {
                        Label("playlist.view", systemImage: "list.bullet")
                        Text(playlist.name)
                    }
                }
                
                Button {
                    addToPlaylistSheetPresented.toggle()
                } label: {
                    Label("playlist.add", systemImage: "plus")
                }
            } label: {
                Text(track.artistName ?? String(localized: "artist.unknown"))
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.thinMaterial)
            .modifier(HoverEffectModifier())
            .sheet(isPresented: $addToPlaylistSheetPresented) {
                PlaylistAddSheet(track: track)
            }
        }
    }
}
