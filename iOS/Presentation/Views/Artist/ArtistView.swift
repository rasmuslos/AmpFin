//
//  ArtistView.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI
import AFBaseKit

struct ArtistView: View {
    @Environment(\.libraryDataProvider) var dataProvider
    
    let artist: Artist
    
    @State var albums: [Album]?
    @State var sortOrder = SortSelector.getSortOrder()
    
    var body: some View {
        ScrollView {
            if artist.cover != nil {
                Header(artist: artist)
            } else {
                Color.clear
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                Task {
                                    try? await artist.startInstantMix()
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
                SortSelector(sortOrder: $sortOrder)
            }
            
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
        }
        .navigationTitle(artist.name)
        .modifier(IgnoreSafeAreaModifier(ignoreSafeArea: artist.cover != nil))
        .task(loadAlbums)
        .onChange(of: sortOrder) {
            Task {
                await loadAlbums()
            }
        }
        .modifier(NowPlayingBarSafeAreaModifier())
    }
}

// MARK: Helper

extension ArtistView {
    @Sendable
    func loadAlbums() async {
        albums = try? await dataProvider.getArtistAlbums(id: artist.id, sortOrder: sortOrder, ascending: true)
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
