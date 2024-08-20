//
//  ArtistsView.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI
import AmpFinKit

internal struct ArtistsView: View {
    @Environment(\.libraryDataProvider) private var dataProvider
    
    let albumOnly: Bool
    
    @State private var working = false
    @State private var success = false
    @State private var failure = false
    
    @State private var count = 0
    @State private var artists = [Artist]()
    
    @State private var search: String = ""
    @State private var task: Task<Void, Error>?
    
    var body: some View {
        Group {
            if success {
                List {
                    ArtistList(artists: artists, count: count) {
                        loadArtists(reset: false)
                    }
                    .padding(.horizontal, 20)
                }
                .listStyle(.plain)
                .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "search.artists")
            } else if failure {
                ErrorView()
            } else {
                LoadingView()
            }
        }
        .navigationTitle(albumOnly ? "title.albumArtists" : "title.artists")
        .modifier(NowPlaying.SafeAreaModifier())
        .onAppear {
            if artists.isEmpty {
                loadArtists(reset: true)
            }
        }
        .onDisappear {
            task?.cancel()
        }
        .onChange(of: search) {
            loadArtists(reset: true)
        }
        .refreshable {
            await withTaskCancellationHandler {
                loadArtists(reset: true)
            } onCancel: {
                task?.cancel()
            }
        }
    }
    
    private func loadArtists(reset: Bool) {
        failure = false
        
        if reset {
            count = 0
            artists = []
            
            working = false
        }
        
        guard !working, count == 0 || count > artists.count else {
            return
        }
        
        working = true
        
        task?.cancel()
        task = Task.detached(priority: .userInitiated) {
            guard let result = try? await dataProvider.artists(limit: 100, startIndex: artists.count, albumOnly: albumOnly, search: search) else {
                await MainActor.withAnimation {
                    failure = true
                }
                return
            }
            
            try Task.checkCancellation()
            
            await MainActor.withAnimation {
                count = result.1
                artists += result.0
                
                success = true
                working = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        ArtistsView(albumOnly: false)
    }
}

#Preview {
    NavigationStack {
        ArtistsView(albumOnly: true)
    }
}
