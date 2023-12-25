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
            Header(artist: artist)
            
            if let albums = albums {
                AlbumGrid(albums: albums)
                    .padding()
            }
            
            if let overview = artist.overview {
                Text(overview)
                    .padding()
                    .background {
                        LinearGradient(colors: [
                            .clear,
                            Color(UIColor.secondarySystemBackground),
                        ], startPoint: .top, endPoint: .bottom)
                    }
            }
        }
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SortSelector(sortOrder: $sortOrder)
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
                Button {
                    Task {
                        try? await artist.startInstantMix()
                    }
                } label: {
                    Image(systemName: "play.circle.fill")
                }
            }
        }
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
}

#Preview {
    NavigationStack {
        ArtistView(artist: Artist.fixture)
    }
}
