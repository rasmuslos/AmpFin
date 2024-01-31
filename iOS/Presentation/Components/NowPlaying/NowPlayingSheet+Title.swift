//
//  NowPlayingSheet+Title.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AFBase
import AFPlayback

// MARK: Cover

extension NowPlayingSheet {
    struct Cover: View {
        let track: Track
        let namespace: Namespace.ID
        @Binding var playing: Bool
        
        var body: some View {
            Spacer()
            
            ItemImage(cover: track.cover)
                .scaleEffect(playing ? 1 : 0.8)
                .animation(.spring(duration: 0.3, bounce: 0.6), value: playing)
                .matchedGeometryEffect(id: "image", in: namespace, properties: .frame, anchor: .topLeading)
            
            Spacer()
            
            HStack {
                VStack(alignment: .leading) {
                    Text(track.name)
                        .bold()
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                        .matchedGeometryEffect(id: "title", in: namespace, properties: .frame, anchor: .topLeading)
                    ArtistsMenu(track: track)
                        .matchedGeometryEffect(id: "artist", in: namespace, properties: .frame, anchor: .topLeading)
                }
                .font(.system(size: 18))
                
                Spacer()
                
                FavoriteButton(track: track)
                    .matchedGeometryEffect(id: "menu", in: namespace, properties: .frame, anchor: .topLeading)
            }
            .padding(.vertical)
        }
    }
}

// MARK: Small Title

extension NowPlayingSheet {
    struct SmallTitle: View {
        let track: Track
        let namespace: Namespace.ID
        @Binding var currentTab: Tab
        
        var body: some View {
            HStack() {
                ItemImage(cover: track.cover)
                    .frame(width: 60, height: 60)
                    .matchedGeometryEffect(id: "image", in: namespace, properties: .frame, anchor: .topLeading)
                    .onTapGesture {
                        withAnimation {
                            currentTab = .cover
                        }
                    }
                
                VStack(alignment: .leading) {
                    Text(track.name)
                        .lineLimit(1)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .matchedGeometryEffect(id: "title", in: namespace, properties: .frame, anchor: .topLeading)
                    ArtistsMenu(track: track)
                        .font(.subheadline)
                        .matchedGeometryEffect(id: "artist", in: namespace, properties: .frame, anchor: .topLeading)
                }
                
                Spacer()
                
                FavoriteButton(track: track)
                    .matchedGeometryEffect(id: "menu", in: namespace, properties: .frame, anchor: .topLeading)
            }
            .padding(.top, 40)
        }
    }
}

// MARK: favorite button

extension NowPlayingSheet {
    struct FavoriteButton: View {
        let track: Track
        
        var body: some View {
            if AudioPlayer.current.source == .local {
                Button {
                    Task.detached {
                        await track.setFavorite(favorite: !track.favorite)
                    }
                } label: {
                    Image(systemName: track.favorite ? "heart.fill" : "heart")
                        .font(.system(size: 24))
                        .symbolRenderingMode(.palette)
                        .contentTransition(.symbolEffect(.replace))
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: artist menu

extension NowPlayingSheet {
    struct ArtistsMenu: View {
        let track: Track
        
        var body: some View {
            Menu {
                Button(action: {
                    NotificationCenter.default.post(name: NavigationRoot.navigateAlbumNotification, object: track.album.id)
                }) {
                    Label("album.view", systemImage: "square.stack")
                    
                    if let albumName = track.album.name {
                        Text(albumName)
                    }
                }
                
                if let artistId = track.artists.first?.id, let artistName = track.artists.first?.name {
                    Button(action: {
                        NotificationCenter.default.post(name: NavigationRoot.navigateArtistNotification, object: artistId)
                    }) {
                        Label("artist.view", systemImage: "music.mic")
                        Text(artistName)
                    }
                }
            } label: {
                Text(track.artistName ?? String(localized: "artist.unknown"))
                    .lineLimit(1)
            }
            .foregroundStyle(.secondary)
            .padding(.vertical, -9)
        }
    }
}
