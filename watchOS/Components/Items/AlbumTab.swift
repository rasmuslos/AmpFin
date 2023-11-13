//
//  AlbumTab.swift
//  watchOS
//
//  Created by Rasmus Krämer on 13.11.23.
//

import SwiftUI
import UIKit
import MusicKit
import TipKit
import UIImageColors

struct AlbumTab: View {
    let album: Album
    
    @State var backgroundColor: Color?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Button {
                // this is so incredibly stupid
            } label: {
                VStack {
                    ItemImage(cover: album.cover)
                    
                    VStack {
                        Text(album.name)
                            .font(.caption)
                        Text(album.artists.map { $0.name }.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)
                    .multilineTextAlignment(.center)
                    .ignoresSafeArea(edges: .bottom)
                    .containerBackground(backgroundColor?.gradient ?? Color.accentColor.gradient, for: .tabView)
                }
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture()
                .onEnded { _ in
                    startPlayback(shuffle: false)
                })
            .simultaneousGesture(LongPressGesture(maximumDistance: 1)
                .onEnded { _ in
                    startPlayback(shuffle: true)
                })
            .onAppear {
                Task.detached {
                    if let cover = album.cover, let data = try? Data(contentsOf: cover.url) {
                        let image = UIImage(data: data)
                        if let colors = image?.getColors(quality: .lowest) {
                            backgroundColor = Color(colors.background)
                        }
                    }
                }
            }
            
            /*
            TipView(ShuffleTip())
                .padding()
             */
        }
    }
}

// MARK: Playback

extension AlbumTab {
    private func startPlayback(shuffle: Bool) {
        Task {
            if let tracks = try? await JellyfinClient.shared.getAlbumTracks(id: album.id) {
                AudioPlayer.shared.startPlayback(tracks: tracks, startIndex: 0, shuffle: shuffle)
            }
        }
    }
}

#Preview {
    TabView {
        AlbumTab(album: Album.fixture)
    }
    .tabViewStyle(.verticalPage)
}
