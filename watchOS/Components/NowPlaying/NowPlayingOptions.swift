//
//  NowPlayingOptions.swift
//  watchOS
//
//  Created by Rasmus Krämer on 15.11.23.
//

import SwiftUI
import MusicKit
import ConnectivityKit

extension NowPlayingModifier {
    struct OptionsSheet: View {
        @State var fetchingRemoteTrack = true
        
        @State var trackId: String?
        @State var name: String?
        @State var artist: String?
        @State var cover: URL?
        @State var favorite: Bool?
        
        // this only works for local tracks right now, might make it work for remote ones sometime
        var body: some View {
            if let track = AudioPlayer.shared.nowPlaying {
                VStack {
                    Cover(name: track.name, artist: track.artists.map { $0.name }.joined(separator: ", "), cover: track.cover)
                    
                    Button {
                        Task {
                            await track.setFavorite(favorite: !track.favorite)
                        }
                    } label: {
                        Label("favorite", systemImage: track.favorite ? "heart.fill" : "heart")
                    }
                    .padding()
                }
                .ignoresSafeArea(edges: .bottom)
            } else if fetchingRemoteTrack {
                LoadingView()
                    .onAppear {
                        ConnectivityKit.shared.sendMessage(NowPlayingMessage() { trackId, name, artist, cover, favorite in
                            self.trackId = trackId
                            self.name = name
                            self.artist = artist
                            self.cover = cover
                            self.favorite = favorite
                            
                            fetchingRemoteTrack = false
                        })
                    }
            } else if let trackId = trackId, let name = name, let artist = artist, let favorite = favorite {
                VStack {
                    Cover(name: name, artist: artist, cover: cover != nil ? Item.Cover(type: .remote, url: cover!) : nil)
                    
                    Button {
                        print(trackId)
                    } label: {
                        Label("favorite", systemImage: favorite ? "heart.fill" : "heart")
                    }
                    .padding()
                }
                .ignoresSafeArea(edges: .bottom)
            } else {
                ErrorView()
            }
        }
    }
}

// MARK: Helper

extension NowPlayingModifier.OptionsSheet {
    struct Cover: View {
        let name: String
        let artist: String
        let cover: Item.Cover?
        
        var body: some View {
            VStack {
                ItemImage(cover: cover)
                
                Text(name)
                    .font(.caption)
                Text(artist)
                    .foregroundStyle(.secondary)
                    .font(.caption2)
                
                Spacer()
            }
        }
    }
}

#Preview {
    NowPlayingModifier.OptionsSheet()
}
