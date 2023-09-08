//
//  TrackListRow.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct TrackListRow: View {
    let track: Track
    var album: Album? = nil
    
    @State var downloaded = false
    
    var body: some View {
        let showArtist = album == nil || !track.artists.elementsEqual(album!.artists) { $0.id == $1.id }
        
        HStack {
            if album != nil {
                Text(String(track.index.index))
                    .frame(width: 23)
                    // .padding(.horizontal, 7)
            } else {
                ItemImage(cover: track.cover)
                    .frame(width: 45)
            }
            
            VStack(alignment: .leading) {
                Text(track.name)
                    .lineLimit(1)
                    .font(.headline)
                    .padding(.vertical, showArtist ? 0 : 6)
                
                if showArtist {
                    Text(track.artists.map { $0.name }.joined(separator: ", "))
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
            
            Menu {
                
            } label: {
                Image(systemName: "ellipsis")
                    .renderingMode(.original)
                    .foregroundStyle(Color(UIColor.label))
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                AudioPlayer.shared.queueTrack(track, index: 0)
            } label: {
                Label("Play next", systemImage: "text.line.first.and.arrowtriangle.forward")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                AudioPlayer.shared.queueTrack(track, index: AudioPlayer.shared.queue.count)
            } label: {
                Label("Play last", systemImage: "text.line.last.and.arrowtriangle.forward")
            }
            .tint(.blue)
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

extension TrackListRow {
    @Sendable
    func checkDownload() async {
        downloaded = await track.isDownloaded()
    }
}
