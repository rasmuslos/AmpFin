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
    struct LargeTitle: View {
        @Environment(ViewModel.self) private var viewModel
        
        let track: Track
        
        var body: some View {
            Spacer()
            
            ItemImage(cover: track.cover)
                .shadow(radius: 20)
                .scaleEffect(AudioPlayer.current.playing ? 1 : 0.8)
                .animation(.spring(duration: 0.3, bounce: 0.6), value: AudioPlayer.current.playing)
                .matchedGeometryEffect(id: "image", in: viewModel.namespace, anchor: .topLeading)
            
            Spacer()
            
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.name)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                        .matchedGeometryEffect(id: "title", in: viewModel.namespace, properties: .frame, anchor: .topTrailing)
                    
                    ArtistsMenu(track: track)
                        .font(.body)
                        .matchedGeometryEffect(id: "artist", in: viewModel.namespace, properties: .frame, anchor: .topTrailing)
                }
                
                Spacer(minLength: 12)
                
                FavoriteButton(track: track)
                    .matchedGeometryEffect(id: "menu", in: viewModel.namespace, properties: .frame, anchor: .topTrailing)
            }
        }
    }
    
    struct SmallTitle: View {
        @Environment(ViewModel.self) private var viewModel
        
        let track: Track
        
        var body: some View {
            HStack(spacing: 12) {
                ItemImage(cover: track.cover)
                    .shadow(radius: 10)
                    .frame(width: 72, height: 72)
                    .matchedGeometryEffect(id: "image", in: viewModel.namespace, anchor: .bottomTrailing)
                    .transition(.opacity)
                    .onTapGesture {
                        viewModel.select(tab: .cover)
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.name)
                        .lineLimit(1)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .matchedGeometryEffect(id: "title", in: viewModel.namespace, properties: .frame, anchor: .topTrailing)
                    
                    ArtistsMenu(track: track)
                        .font(.body)
                        .matchedGeometryEffect(id: "artist", in: viewModel.namespace, properties: .frame, anchor: .topTrailing)
                }
                
                Spacer()
                
                FavoriteButton(track: track)
                    .matchedGeometryEffect(id: "menu", in: viewModel.namespace, properties: .frame, anchor: .topTrailing)
            }
            .contentShape(.rect)
        }
    }
}

private struct FavoriteButton: View {
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
                    .foregroundStyle(.white.opacity(track.favorite ? 0.8 : 0.2), .white.opacity(track.favorite ? 0.4 : 0.2))
                    .symbolRenderingMode(.palette)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .modifier(HoverEffectModifier())
            .sensoryFeedback(track.favorite ? .increase : .decrease, trigger: track.favorite)
        }
    }
}

private struct ArtistsMenu: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    let track: Track
    
    var body: some View {
        Menu {
            Button(action: { Navigation.navigate(albumId: track.album.id) }) {
                Label("album.view", systemImage: "square.stack")
                
                if let albumName = track.album.name {
                    Text(albumName)
                }
            }
            
            ForEach(track.artists) { artist in
                Button {
                    Navigation.navigate(artistId: artist.id)
                } label: {
                    Label("artist.view", systemImage: "music.mic")
                    Text(artist.name)
                }
            }
            
            if let playbackInfo = AudioPlayer.current.playbackInfo, let playlist = playbackInfo.container as? Playlist {
                Button {
                    Navigation.navigate(playlistId: playlist.id)
                } label: {
                    Label("playlist.view", systemImage: "list.bullet")
                    Text(playlist.name)
                }
            }
            
            Button {
                viewModel.addToPlaylistSheetPresented.toggle()
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
    }
}
