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
        Button {
            
        } label: {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    ItemImage(cover: album.cover)
                        .frame(width: 65)
                    
                    Spacer()
                    
                    Button {
                        
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.plain)
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text(album.name)
                            .font(.caption)
                            .padding(.top)
                            .lineLimit(1)
                        Text(album.artists.map { $0.name }.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
        .padding(10)
        .background(.gray.opacity(0.25))
        .background((backgroundColor ?? Color.accentColor).gradient.opacity(0.3))
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            Task.detached {
                if let cover = album.cover, let data = try? Data(contentsOf: cover.url), let image = UIImage(data: data), let colors = image.getColors(quality: .low) {
                    withAnimation {
                        backgroundColor = Color(colors.background)
                    }
                }
            }
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
