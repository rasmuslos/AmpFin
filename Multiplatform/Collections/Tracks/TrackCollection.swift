//
//  TrackCollection.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 05.06.24.
//

import SwiftUI
import AmpFinKit
import AFPlayback

struct TrackCollection {}

internal extension TrackCollection {
    struct TrackIndexCover: View {
        let track: Track
        let album: Album?
        
        private var size: CGFloat {
            if album == nil {
                return 48
            }
            
            return 24
        }
        
        private var active: Bool {
            AudioPlayer.current.nowPlaying == track
        }
        
        var body: some View {
            Group {
                if album != nil {
                    Text(String(track.index.index))
                        .font(.callout)
                        .bold(track.favorite)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                        .opacity(active ? 0 : 1)
                } else {
                    ItemImage(cover: track.cover)
                }
            }
            .frame(width: size, height: size)
            .overlay {
                ZStack {
                    if album == nil {
                        Color.black.opacity(0.2)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // apparently SwiftUI cannot cope with this symbol effect and enabling it causes all animations to have an abysmal frame-rate... I have no idea why though
                    Image(systemName: "waveform")
                        .font(album == nil ? .body : .caption)
                        .foregroundStyle(album == nil ? .white : .secondary)
                }
                .opacity(active ? 1 : 0)
            }
            .padding(.trailing, 8)
        }
    }
    
    struct TrackPreview: View {
        let track: Track
        
        var body: some View {
            HStack(spacing: 8) {
                ItemImage(cover: track.cover)
                    .frame(width: 44)
                
                VStack(alignment: .leading) {
                    Text(track.name)
                    
                    if let artistName = track.artistName {
                        Text(artistName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background()
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    struct TrackMenu: View {
        @Environment(\.libraryDataProvider) private var dataProvider
        
        let track: Track
        let album: Album?
        
        var deleteCallback: TrackCollection.DeleteCallback = nil
        
        @Binding var lyricsSheetPresented: Bool
        @Binding var addToPlaylistSheetPresented: Bool
        
        @State private var offlineTracker: ItemOfflineTracker?
        
        var body: some View {
            Button {
                AudioPlayer.current.startPlayback(tracks: [track], startIndex: 0, shuffle: false, playbackInfo: .init(container: nil))
            } label: {
                Label("play", systemImage: "play")
            }
            
            Button {
                Task {
                    try? await track.startInstantMix()
                }
            } label: {
                Label("queue.mix", systemImage: "compass.drawing")
            }
            .disabled(!JellyfinClient.shared.online)
            
            Divider()
            
            
            QueueNextButton {
                AudioPlayer.current.queue(track, after: 0, playbackInfo: .init(container: nil, queueLocation: .next))
            }
            QueueLaterButton {
                AudioPlayer.current.queue(track, after: AudioPlayer.current.queue.count, playbackInfo: .init(container: nil, queueLocation: .later))
            }
            
            Divider()
            
            Button {
                track.favorite.toggle()
            } label: {
                Label("favorite", systemImage: track.favorite ? "star.slash" : "star")
            }
            
            Button {
                addToPlaylistSheetPresented.toggle()
            } label: {
                Label("playlist.add", systemImage: "plus")
            }
            .disabled(!JellyfinClient.shared.online)
            
            Divider()
            
            if album == nil {
                NavigationLink(value: .albumLoadDestination(albumId: track.album.id)) {
                    Label("album.view", systemImage: "square.stack")
                    
                    if let name = track.album.name {
                        Text(verbatim: name)
                    }
                }
            }
            
            ForEach(track.artists) { artist in
                NavigationLink(value: .artistLoadDestination(artistId: artist.id)) {
                    Label("artist.view", systemImage: "music.mic")
                    Text(artist.name)
                }
                .disabled(!dataProvider.supportsArtistLookup)
            }
            
            Divider()
                .onAppear {
                    offlineTracker = track.offlineTracker
                }
            
            Button {
                lyricsSheetPresented.toggle()
            } label: {
                Label("lyrics.view", systemImage: "text.bubble")
            }
            
            if let offlineTracker = offlineTracker, offlineTracker.status == .downloaded {
                Button {
                    try? OfflineManager.shared.update(trackId: track.id)
                } label: {
                    Label("download.update", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(!JellyfinClient.shared.online)
            }
            
            if let deleteCallback = deleteCallback {
                Divider()
                
                Button(role: .destructive) {
                    deleteCallback(track)
                } label: {
                    Label("playlist.remove", systemImage: "trash.fill")
                }
            }
        }
    }
}

internal extension TrackCollection {
    typealias LoadCallback = (() -> Void)?
    
    typealias DeleteCallback = ((_ track: Track) -> Void)?
    typealias MoveCallback = ((_ track: Track, _ to: Int) -> Void)?
}
