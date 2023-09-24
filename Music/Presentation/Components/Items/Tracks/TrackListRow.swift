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
    let startPlayback: () -> ()
    
    @State var downloaded = false
    
    var body: some View {
        let showArtist = album == nil || !track.artists.elementsEqual(album!.artists) { $0.id == $1.id }
        
        HStack {
            Button {
                startPlayback()
            } label: {
                if album != nil {
                    Text(String(track.index.index))
                        .frame(width: 23)
                        .fontDesign(.rounded)
                    // .padding(.horizontal, 7)
                } else {
                    ItemImage(cover: track.cover)
                        .frame(width: 45)
                }
                
                VStack(alignment: .leading) {
                    Text(track.name)
                        .lineLimit(1)
                        .font(.body)
                        .padding(.vertical, showArtist ? 0 : 6)
                    
                    if showArtist {
                        Text(track.artists.map { $0.name }.joined(separator: ", "))
                            .lineLimit(1)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 5)
                
                Spacer()
            }
            .buttonStyle(.plain)
            
            if downloaded {
                Image(systemName: "arrow.down.circle.fill")
                    .imageScale(.small)
                    .padding(.horizontal, 4)
                    .foregroundStyle(.secondary)
            }
            
            Menu {
                PlayNextButton(track: track)
                PlayLastButton(track: track)
                
                Divider()
                
                if album == nil {
                    NavigationLink(destination: AlbumLoadView(albumId: track.album.id)) {
                        Label("View album", systemImage: "square.stack")
                    }
                }
                
                Divider()
                
                FavoriteButton(track: track)
            } label: {
                Image(systemName: "ellipsis")
                    .renderingMode(.original)
                    .foregroundStyle(Color(UIColor.label))
                    .padding(.vertical, 10)
                    .padding(.leading, 0)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            PlayNextButton(track: track)
        }
        .swipeActions(edge: .leading) {
            PlayLastButton(track: track)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            FavoriteButton(track: track)
        }
        .task(checkDownload)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.DownloadUpdated)) { _ in
            Task.detached {
                await checkDownload()
            }
        }
    }
}

// MARK: Buttons

extension TrackListRow {
    struct PlayNextButton: View {
        let track: Track
        
        var body: some View {
            Button {
                AudioPlayer.shared.queueTrack(track, index: 0)
            } label: {
                Label("Play next", systemImage: "text.line.first.and.arrowtriangle.forward")
            }
            .tint(.orange)
        }
    }
    struct PlayLastButton: View {
        let track: Track
        
        var body: some View {
            Button {
                AudioPlayer.shared.queueTrack(track, index: AudioPlayer.shared.queue.count)
            } label: {
                Label("Play last", systemImage: "text.line.last.and.arrowtriangle.forward")
            }
            .tint(.blue)
        }
    }
    
    struct FavoriteButton: View {
        let track: Track
        
        var body: some View {
            Button {
                Task {
                    try? await track.setFavorite(favorite: !track.favorite)
                }
            } label: {
                Label("Favorite", systemImage: track.favorite ? "heart.fill" : "heart")
            }
            .tint(.red)
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
