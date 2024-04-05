//
//  AlbumRow.swift
//  Music
//
//  Created by Rasmus Krämer on 17.10.23.
//

import SwiftUI
import AFBase

struct AlbumRow: View {
    let title: String
    let albums: [Album]
    @Environment(\.displayScale) var displayScale
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                    .padding(.leading)
                    .padding(.bottom, 0)
                    .padding(.top, 10)
                
                Image(systemName: "chevron.right.circle.fill")
                    .imageScale(.small)
            }
            .background {
                NavigationLink {
                    ScrollView {
                        AlbumsGrid(albums: albums)
                    }
                    .navigationTitle(title)
                    .padding(.horizontal)
                    .modifier(NowPlayingBarSafeAreaModifier())
                } label: {
                    EmptyView()
                }
                .opacity(0)
            }
            
            let size = 400 / displayScale
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(albums) { album in
                        NavigationLink(destination: AlbumView(album: album)) {
                            AlbumCover(album: album)
                                .frame(width: size)
                                .padding(.leading, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .scrollTargetLayout()
                .padding(.leading, 10)
                .padding(.trailing, 20)
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

#Preview {
    NavigationStack {
        List {
            AlbumRow(title: "Album fixtures", albums: [
                Album.fixture,
                Album.fixture,
                Album.fixture,
                Album.fixture,
                Album.fixture,
                Album.fixture,
            ])
        }
        .listStyle(.plain)
    }
}
