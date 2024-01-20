//
//  PlaylistView.swift
//  tvOS
//
//  Created by Rasmus Krämer on 20.01.24.
//

import SwiftUI
import AFBaseKit

struct PlaylistView: View {
    let playlist: Playlist
    
    @State var tracks = [Track]()
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                ItemImage(cover: playlist.cover)
                    .padding(.bottom, 100)
                    .shadow(radius: 25)
                
                Group {
                    Text("tracks.count.large \(playlist.trackCount)")
                    + Text(verbatim: " • ")
                    + Text("playlist.duration \(playlist.duration.timeLeft())")
                }
                .foregroundStyle(.secondary)
                .font(.subheadline)
                Text(playlist.name)
                    .font(.title3)
            }
            .padding(.trailing, 50)
            
            if tracks.isEmpty {
                HStack {
                    Spacer()
                    
                    ProgressView()
                        .onAppear {
                            Task {
                                tracks = try await JellyfinClient.shared.getTracks(playlistId: playlist.id)
                            }
                        }
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(tracks) { track in
                            Button {
                                
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(track.name)
                                        
                                        if let artistName = track.artistName {
                                            Text(artistName)
                                                .foregroundStyle(.secondary)
                                                .font(.subheadline)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Text(track.runtime.timeLeft())
                                        .fontDesign(.rounded)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .font(.body)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 80)
                }
            }
        }
        .ignoresSafeArea(edges: .trailing)
        .toolbar(.hidden, for: .tabBar)
    }
}

#Preview {
    PlaylistView(playlist: Playlist.fixture)
}
