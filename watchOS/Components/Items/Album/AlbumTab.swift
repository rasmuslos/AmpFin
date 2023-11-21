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
        .background(.white.opacity(0.25))
        .background {
            ItemImage(cover: album.cover)
                .scaleEffect(3)
                .blur(radius: 30)
        }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
