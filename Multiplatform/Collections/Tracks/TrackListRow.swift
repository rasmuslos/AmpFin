//
//  TrackListRow.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AFBase
import AFOffline
import AFPlayback

struct TrackListRow: View {
    let track: Track
    var album: Album? = nil
    
    var disableMenu: Bool = false
    
    var deleteCallback: TrackList.DeleteCallback = nil
    let startPlayback: () -> ()
    
    @State private var addToPlaylistSheetPresented = false
    
    private var size: CGFloat {
        album == nil ? 50 : 23
    }
    private var showArtist: Bool {
        album == nil || !track.artists.elementsEqual(album!.artists) { $0.id == $1.id }
    }
    
    private var playbackIndicator: some View {
        Image(systemName: "waveform")
            .symbolEffect(.variableColor.iterative, isActive: AudioPlayer.current.playing)
    }
    private var isPlaying: Bool {
        AudioPlayer.current.nowPlaying == track
    }
    
    var body: some View {
        HStack {
            Button {
                startPlayback()
            } label: {
                HStack(spacing: 0) {
                    Group {
                        if album != nil {
                            if isPlaying {
                                playbackIndicator
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(String(track.index.index))
                                    .fontDesign(.rounded)
                                    .bold(track.favorite)
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 4)
                            }
                        } else {
                            ItemImage(cover: track.cover)
                                .overlay {
                                    if isPlaying {
                                        ZStack {
                                            Color.black.opacity(0.2)
                                                .clipShape(RoundedRectangle(cornerRadius: 7))
                                            
                                            playbackIndicator
                                                .font(.body)
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                        }
                    }
                    .frame(width: size, height: size)
                    .transition(.blurReplace)
                    .id(track.id)
                    .padding(.trailing, .connectedSpacing)
                    
                    VStack(alignment: .leading) {
                        Text(track.name)
                            .lineLimit(1)
                            .font(.body)
                            .bold(track.favorite && album == nil)
                            .padding(.vertical, showArtist ? 0 : 6)
                        
                        if showArtist, let artistName = track.artistName {
                            Text(artistName)
                                .lineLimit(1)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 5)
                    
                    Spacer()
                }
                .contentShape(.hoverMenuInteraction, Rectangle())
            }
            .buttonStyle(.plain)
            
            DownloadIndicator(item: track)
            
            if !disableMenu {
                Menu {
                    TrackMenu(track: track, album: album, deleteCallback: deleteCallback, addToPlaylistSheetPresented: $addToPlaylistSheetPresented)
                } label: {
                    Label("more", systemImage: "ellipsis")
                        .labelStyle(.iconOnly)
                        .font(.caption)
                        .imageScale(.large)
                        .foregroundStyle(Color(UIColor.label))
                        .padding(.vertical, 10)
                        .padding(.leading, 0)
                }
                .buttonStyle(.plain)
                .modifier(ButtonHoverEffectModifier())
                .popoverTip(InstantMixTip())
            }
        }
        .padding(7)
        .contentShape([.hoverMenuInteraction, .dragPreview], RoundedRectangle(cornerRadius: 7))
        .draggable(track) {
            TrackPreview(track: track)
        }
        .contextMenu {
            TrackMenu(track: track, album: album, deleteCallback: deleteCallback, addToPlaylistSheetPresented: $addToPlaylistSheetPresented)
        } preview: {
            TrackPreview(track: track)
        }
        .padding(-7)
        .sheet(isPresented: $addToPlaylistSheetPresented) {
            PlaylistAddSheet(track: track)
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
        .swipeActions(edge: .trailing) {
            AddToPlaylistButton(track: track, addToPlaylistSheetPresented: $addToPlaylistSheetPresented)
        }
    }
}

// MARK: Buttons

extension TrackListRow {
    struct TrackPreview: View {
        let track: Track
        
        var body: some View {
            HStack {
                ItemImage(cover: track.cover)
                    .frame(width: 45)
                
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
            .padding(.connectedSpacing)
            .background()
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
    }
    
    struct TrackMenu: View {
        @Environment(\.libraryDataProvider) private var dataProvider
        
        let track: Track
        let album: Album?
        
        let deleteCallback: TrackList.DeleteCallback
        
        let offlineTracker: ItemOfflineTracker
        
        @Binding var addToPlaylistSheetPresented: Bool
        
        init(track: Track, album: Album?, deleteCallback: TrackList.DeleteCallback, addToPlaylistSheetPresented: Binding<Bool>) {
            self.track = track
            self.album = album
            self.deleteCallback = deleteCallback
            
            offlineTracker = track.offlineTracker
            
            _addToPlaylistSheetPresented = addToPlaylistSheetPresented
        }
        
        var body: some View {
            Button {
                AudioPlayer.current.startPlayback(tracks: [track], startIndex: 0, shuffle: false, playbackInfo: .init(container: nil))
            } label: {
                Label("play", systemImage: "play")
            }
            
            Divider()
            
            PlayNextButton(track: track)
            PlayLastButton(track: track)
            
            Divider()
            
            FavoriteButton(track: track)
            
            Button {
                Task {
                    try? await track.startInstantMix()
                }
            } label: {
                Label("queue.mix", systemImage: "compass.drawing")
            }
            .disabled(!JellyfinClient.shared.online)
            
            AddToPlaylistButton(track: track, addToPlaylistSheetPresented: $addToPlaylistSheetPresented)
            
            Divider()
            
            if album == nil {
                NavigationLink(destination: AlbumLoadView(albumId: track.album.id)) {
                    Label("album.view", systemImage: "square.stack")
                    
                    if let name = track.album.name {
                        Text(verbatim: name)
                    }
                }
            }
            
            if let artist = track.artists.first {
                NavigationLink(destination: ArtistLoadView(artistId: artist.id)) {
                    Label("artist.view", systemImage: "music.mic")
                    Text(artist.name)
                }
                .disabled(!dataProvider.supportsArtistLookup)
            }
            
            if let deleteCallback = deleteCallback {
                Divider()
                
                Button(role: .destructive) {
                    deleteCallback(track)
                } label: {
                    Label("playlist.remove", systemImage: "trash.fill")
                }
            }
            
            if offlineTracker.status == .downloaded {
                Divider()
                
                Button {
                    try? OfflineManager.shared.update(trackId: track.id)
                } label: {
                    Label("download.update", systemImage: "arrow.triangle.2.circlepath")
                }
            }
        }
    }
    
    struct PlayNextButton: View {
        let track: Track
        
        var body: some View {
            Button {
                AudioPlayer.current.queueTrack(track, index: 0, playbackInfo: .init(container: nil, queueLocation: .next))
            } label: {
                Label("queue.next", systemImage: "text.line.first.and.arrowtriangle.forward")
            }
            .tint(.orange)
        }
    }
    struct PlayLastButton: View {
        let track: Track
        
        var body: some View {
            Button {
                AudioPlayer.current.queueTrack(track, index: AudioPlayer.current.queue.count, playbackInfo: .init(container: nil, queueLocation: .later))
            } label: {
                Label("queue.last", systemImage: "text.line.last.and.arrowtriangle.forward")
            }
            .tint(.blue)
        }
    }
    
    struct FavoriteButton: View {
        let track: Track
        
        var body: some View {
            Button {
                Task {
                    await track.setFavorite(favorite: !track.favorite)
                }
            } label: {
                Label("favorite", systemImage: track.favorite ? "heart.slash.fill" : "heart.fill")
            }
            .tint(.orange)
        }
    }
    
    struct AddToPlaylistButton: View {
        let track: Track
        @Binding var addToPlaylistSheetPresented: Bool
        
        var body: some View {
            Button {
                addToPlaylistSheetPresented.toggle()
            } label: {
                Label("playlist.add", systemImage: "plus")
            }
            .disabled(!JellyfinClient.shared.online)
            .tint(.green)
        }
    }
}

extension TrackListRow {
    static let placeholder: some View = TrackListRow(
        track: .init(
            id: "placeholder",
            name: "Placeholder",
            cover: nil,
            favorite: false,
            album: .init(id: "placeholder", name: "Placerholder", artists: []),
            artists: [],
            lufs: nil,
            index: .init(index: 0, disk: 0),
            runtime: 0,
            playCount: 0,
            releaseDate: nil),
        album: nil,
        disableMenu: true,
        deleteCallback: nil,
        startPlayback: {})
    .redacted(reason: .placeholder)
}

#Preview {
    TrackListRow.placeholder
}
