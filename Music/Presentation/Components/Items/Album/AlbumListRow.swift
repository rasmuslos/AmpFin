//
//  AlbumListRow.swift
//  Music
//
//  Created by Rasmus Krämer on 09.09.23.
//

import SwiftUI

struct AlbumListRow: View {
    let album: Album
    
    @State var downloaded = false
    
    var body: some View {
        HStack {
            ItemImage(cover: album.cover)
                .frame(width: 45)
            
            VStack(alignment: .leading) {
                Text(album.name)
                    .lineLimit(1)
                    .font(.headline)
                
                if album.artists.count > 0 {
                    Text(album.artists.map { $0.name }.joined(separator: ", "))
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 5)
            
            Spacer()
            
            if downloaded {
                Image(systemName: "arrow.down.circle.fill")
                    .imageScale(.small)
                    .padding(.horizontal, 4)
                    .foregroundStyle(.secondary)
            }
        }
        .task(checkDownload)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.DownloadUpdated)) { _ in
            Task.detached {
                await checkDownload()
            }
        }
    }
}

// MARK: Helper

extension AlbumListRow {
    @Sendable
    func checkDownload() async {
        downloaded = await album.isOffline()
    }
}


#Preview {
    List {
        AlbumListRow(album: Album.fixture)
        AlbumListRow(album: Album.fixture)
        AlbumListRow(album: Album.fixture)
        AlbumListRow(album: Album.fixture)
        AlbumListRow(album: Album.fixture)
    }
    .listStyle(.plain)
}
