//
//  ArtistView.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI
import AFBase
import AFPlayback

struct ArtistView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    let artist: Artist
    
    @State var albums: [Album]?
    @State var ascending = SortSelector.getAscending()
    @State var sortOrder = SortSelector.getSortOrder()
    
    var sortState: [String] {[
        ascending.description,
        sortOrder.rawValue,
    ]}
    
    var body: some View {
        ScrollView {
            if artist.cover != nil {
                Header(artist: artist)
            } else {
                Color.clear
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                if UserDefaults.standard.bool(forKey: "artistInstantMix") {
                                    Task {
                                        try? await artist.startInstantMix()
                                    }
                                } else {
                                    Task {
                                        let tracks = try await dataProvider.getArtistTracks(id: artist.id)
                                        AudioPlayer.current.startPlayback(tracks: tracks, startIndex: 0, shuffle: false, playbackInfo: .init())
                                    }
                                }
                            } label: {
                                Image(systemName: "play.circle.fill")
                            }
                        }
                    }
            }
            
            if let albums = albums, !albums.isEmpty {
                HStack {
                    Text("artist.albums")
                        .font(.headline)
                    
                    Spacer()
                }
                .padding(.top, artist.cover == nil ? 0 : 17)
                .padding(.horizontal)
                
                AlbumsGrid(albums: albums)
                    .padding()
            } else {
                Text("artist.empty")
                    .font(.headline.smallCaps())
                    .foregroundStyle(.secondary)
                    .padding(.top, 100)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await artist.setFavorite(favorite: !artist.favorite)
                    }
                } label: {
                    Label("favorite", systemImage: artist.favorite ? "heart.fill" : "heart")
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                SortSelector(ascending: $ascending, sortOrder: $sortOrder)
            }
        }
        .navigationTitle(artist.name)
        .onChange(of: sortState) {
            Task {
                await loadAlbums()
            }
        }
        .modifier(NowPlayingBarSafeAreaModifier())
        .modifier(IgnoreSafeAreaModifier(ignoreSafeArea: artist.cover != nil))
        .task(loadAlbums)
        .userActivity("io.rfk.ampfin.artist") {
            $0.title = artist.name
            $0.isEligibleForHandoff = true
            $0.persistentIdentifier = artist.id
            $0.userInfo = [
                "artistId": artist.id
            ]
        }
    }
}

// MARK: Helper

extension ArtistView {
    @Sendable
    func loadAlbums() async {
        albums = try? await dataProvider.getArtistAlbums(id: artist.id, sortOrder: sortOrder, ascending: ascending)
    }
    
    // truly stupid
    struct IgnoreSafeAreaModifier: ViewModifier {
        let ignoreSafeArea: Bool
        
        func body(content: Content) -> some View {
            if ignoreSafeArea {
                content
                    .ignoresSafeArea(edges: .top)
            } else {
                content
            }
        }
    }
}

#Preview {
    NavigationStack {
        ArtistView(artist: Artist.fixture)
    }
}
