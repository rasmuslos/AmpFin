//
//  ArtistView.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI
import Defaults
import AmpFinKit

internal struct ArtistView: View {
    @Environment(\.libraryDataProvider) private var dataProvider
    
    let artist: Artist
    
    @State private var sortAscending = false
    @State private var sortOrder: ItemSortOrder = .released
    
    @State private var tracks = [Track]()
    
    @State private var count = 0
    @State private var albums = [Album]()
    
    @State private var working = false
    @State private var task: Task<Void, Error>?
    
    private var sortState: [String] {[
        sortAscending.description,
        sortOrder.hashValue.description,
    ]}
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if artist.cover != nil {
                    Header(artist: artist)
                        .padding(.bottom, 12)
                }
                
                if !tracks.isEmpty {
                    HStack {
                        Text("artist.tracks")
                            .font(.headline)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    TrackGrid(tracks: tracks, container: artist)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                }
                
                if !albums.isEmpty {
                    HStack {
                        Text("artist.albums")
                            .font(.headline)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    AlbumGrid(albums: albums, count: count) {
                        loadAlbums(reset: false)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 20)
                } else {
                    Text("artist.empty")
                        .font(.headline.smallCaps())
                        .foregroundStyle(.secondary)
                        .padding(.top, 100)
                }
            }
        }
        .modifier(Toolbar(artist: artist, sortOrder: $sortOrder, ascending: $sortAscending))
        .modifier(NowPlaying.SafeAreaModifier())
        .environment(\.displayContext, .artist)
        .task {
            await loadTracks()
        }
        .onAppear {
            if albums.isEmpty {
                loadAlbums(reset: true)
            }
        }
        .onDisappear {
            task?.cancel()
        }
        .onChange(of: sortState) {
            loadAlbums(reset: true)
        }
        .refreshable {
            await withTaskCancellationHandler {
                loadAlbums(reset: true)
            } onCancel: {
                Task {
                    await task?.cancel()
                }
            }
        }
        .userActivity("io.rfk.ampfin.artist") {
            $0.title = artist.name
            $0.isEligibleForHandoff = true
            $0.persistentIdentifier = artist.id
            $0.targetContentIdentifier = "artist:\(artist.id)"
            $0.userInfo = [
                "artistId": artist.id
            ]
            $0.webpageURL = URL(string: JellyfinClient.shared.serverUrl.appending(path: "web").absoluteString + "#")!.appending(path: "details").appending(queryItems: [
                .init(name: "id", value: artist.id),
            ])
        }
    }
    
    private func loadTracks() async {
        guard let tracks = try? await dataProvider.tracks(artistId: artist.id, sortOrder: .plays, ascending: false) else {
            return
        }
        
        self.tracks = tracks
    }
    
    private func loadAlbums(reset: Bool) {
        if reset {
            count = 0
            albums = []
            
            working = false
        }
        
        guard !working, count == 0 || count > albums.count else {
            return
        }
        
        working = true
        
        task?.cancel()
        task = Task.detached(priority: .userInitiated) {
            guard let result = try? await dataProvider.albums(artistId: artist.id, limit: 100, startIndex: albums.count, sortOrder: sortOrder, ascending: sortAscending) else {
                return
            }
            
            try Task.checkCancellation()
            
            await MainActor.withAnimation {
                count = result.1
                albums += result.0
                
                working = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        ArtistView(artist: Artist.fixture)
    }
}

#Preview {
    NavigationStack {
        ArtistView(artist: {
            let artist = Artist.fixture
            artist.cover = nil
            
            return artist
        }())
    }
}
