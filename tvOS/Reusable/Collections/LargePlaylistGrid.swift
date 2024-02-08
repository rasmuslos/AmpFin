//
//  LargeAlbumsRow.swift
//  tvOS
//
//  Created by Rasmus Krämer on 19.01.24.
//

import SwiftUI
import AFBase

struct LargePlaylistGrid: View {
    let playlists: [Playlist]
    
    var body: some View {
        let size = (UIScreen.main.bounds.width - 90 * 3) / 2
        
        ScrollView(.horizontal) {
            LazyHStack(spacing: 40) {
                ForEach(playlists) { playlist in
                    PlaylistGridItem(playlist: playlist)
                        .frame(width: size)
                        .padding(.vertical, 45)
                }
            }
            .padding(.horizontal, 45)
        }
        .focusSection()
    }
}

extension LargePlaylistGrid {
    struct PlaylistGridItem: View {
        let playlist: Playlist
        
        @State var width: CGFloat = .zero
        @State var tracks = [Track]()
        
        var body: some View {
            NavigationLink(destination: PlaylistView(playlist: playlist)) {
                Rectangle()
                    .frame(height: 80 + width * (2/5) + 140)
                    .overlay(alignment: .topLeading) {
                        ZStack {
                            GeometryReader { proxy in
                                Color.clear
                                    .onAppear {
                                        width = proxy.size.width - (80 + 40)
                                    }
                            }
                            
                            VStack(spacing: 0) {
                                HStack(spacing: 20) {
                                    ItemImage(cover: tracks.first?.cover ?? playlist.cover)
                                        .frame(width: width * (2/5))
                                    
                                    if !tracks.isEmpty {
                                        ForEach(0..<3) { offset in
                                            VStack(spacing: 20) {
                                                ForEach(1..<3) { index in
                                                    if let top = tracks.get(offset + index) {
                                                        ItemImage(cover: top.cover)
                                                    } else {
                                                        Color.clear
                                                            .aspectRatio(1, contentMode: .fit)
                                                    }
                                                }
                                            }
                                            .frame(width: width / 5 - 10)
                                        }
                                    } else {
                                        Spacer()
                                            .overlay {
                                                ProgressView()
                                            }
                                            .onAppear {
                                                Task.detached {
                                                    let tracks = try await JellyfinClient.shared.getTracks(playlistId: playlist.id)
                                                    var seenAlbumIds = [String]()
                                                    
                                                    withAnimation {
                                                        self.tracks = tracks.filter {
                                                            if seenAlbumIds.contains($0.album.id) {
                                                                return false
                                                            }
                                                            
                                                            seenAlbumIds.append($0.album.id)
                                                            return $0.cover != nil
                                                        }
                                                    }
                                                }
                                            }
                                    }
                                }
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("tracks.count.large \(playlist.trackCount)")
                                            .font(.subheadline)
                                            .foregroundStyle(.gray)
                                        Text(playlist.name)
                                            .lineLimit(1)
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.top, 40)
                            }
                            .padding(40)
                        }
                    }
                    .foregroundStyle(.clear)
            }
            .buttonStyle(.card)
        }
    }

}

#Preview {
    ScrollView {
        LargePlaylistGrid(playlists: [
            Playlist.fixture,
            Playlist.fixture,
            Playlist.fixture,
            Playlist.fixture,
            Playlist.fixture,
            Playlist.fixture,
            Playlist.fixture,
        ])
    }
    .ignoresSafeArea()
}
