//
//  LibraryView.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct LibraryView: View {
    @Environment(\.defaultMinListRowHeight) var minRowHeight
    
    let dataProvider: LibraryDataProvider
    
    @State var recentAlbums: [Album]?
    
    var body: some View {
        ScrollView {
            List {
                Links()
            }
            .listStyle(.plain)
            .navigationTitle("Library")
            .environment(\.libraryDataProvider, dataProvider)
            .frame(height: CGFloat(Links.count) * minRowHeight)
            
            if let recentAlbums = recentAlbums, recentAlbums.count > 0 {
                HStack {
                    Text("Recently added")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                AlbumGrid(albums: recentAlbums)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .modifier(NowPlayingBarSafeAreaModifier())
        .onAppear(perform: loadRecentAlbums)
        .refreshable(action: loadRecentAlbums)
    }
}

// MARK: Helper

extension LibraryView {
    @Sendable
    func loadRecentAlbums() {
        Task.detached {
            recentAlbums = try? await dataProvider.getRecentAlbums()
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView(dataProvider: OnlineLibraryDataProivder())
    }
}
