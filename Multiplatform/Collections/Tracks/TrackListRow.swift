//
//  TrackListRow.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AmpFinKit
import AFPlayback

struct TrackListRow: View {
    let track: Track
    var container: Item? = nil
    
    var preview: Bool = false
    var deleteCallback: TrackCollection.DeleteCallback = nil
    
    let startPlayback: () -> Void
    
    @State private var lyricsSheetPresented = false
    @State private var addToPlaylistSheetPresented = false
    
    private var album: Album? {
        container as? Album
    }
    private var showArtist: Bool {
        if album == nil {
            return true
        }
        
        return !track.artists.elementsEqual(album!.artists) { $0.id == $1.id }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Button {
                startPlayback()
            } label: {
                HStack(spacing: 0) {
                    TrackCollection.TrackIndexCover(track: track, album: album)
                    
                    VStack(alignment: .leading, spacing: showArtist ? 0 : 2) {
                        Text(track.name)
                            .lineLimit(1)
                            .font(album == nil ? .subheadline : .callout)
                            .bold(album == nil && track.favorite)
                        
                        if showArtist, let artistName = track.artistName {
                            Text(artistName)
                                .lineLimit(1)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer(minLength: 8)
                }
                .contentShape(.hoverMenuInteraction, Rectangle())
            }
            .buttonStyle(.plain)
            .hoverEffectDisabled()
            
            DownloadIndicator(item: track)
            
            if !preview {
                Menu {
                    TrackCollection.TrackMenu(track: track,
                              album: album,
                              deleteCallback: deleteCallback,
                              lyricsSheetPresented: $lyricsSheetPresented,
                              addToPlaylistSheetPresented: $addToPlaylistSheetPresented)
                } label: {
                    Label("more", systemImage: "ellipsis")
                        .labelStyle(.iconOnly)
                        .font(.subheadline)
                        .imageScale(.large)
                        .foregroundStyle(Color(UIColor.label))
                        .padding(.leading, 0)
                }
                .buttonStyle(.plain)
                .hoverEffect(.lift)
                .popoverTip(InstantMixTip())
            }
        }
        .id(track.id)
        .modifier(ActionsModifier(track: track, preview: preview, deleteCallback: deleteCallback, lyricsSheetPresented: $lyricsSheetPresented, addToPlaylistSheetPresented: $addToPlaylistSheetPresented))
    }
}

private struct ActionsModifier: ViewModifier {
    let track: Track
    var container: Item?
    
    var preview: Bool
    var deleteCallback: TrackCollection.DeleteCallback
    
    @Binding var lyricsSheetPresented: Bool
    @Binding var addToPlaylistSheetPresented: Bool
    
    private var album: Album? {
        container as? Album
    }
    
    func body(content: Content) -> some View {
        if preview {
            content
        } else {
            content
                .padding(8)
                .contentShape([.hoverMenuInteraction, .dragPreview], .rect(cornerRadius: 12))
                .hoverEffect(.highlight)
                .draggable(track) {
                    TrackCollection.TrackPreview(track: track)
                }
                .contextMenu {
                    TrackCollection.TrackMenu(track: track,
                                              album: album,
                                              deleteCallback: deleteCallback,
                                              lyricsSheetPresented: $lyricsSheetPresented,
                                              addToPlaylistSheetPresented: $addToPlaylistSheetPresented)
                } preview: {
                    TrackCollection.TrackPreview(track: track)
                }
                .padding(-8)
                .sheet(isPresented: $lyricsSheetPresented) {
                    LyricsSheet(track: track)
                }
                .sheet(isPresented: $addToPlaylistSheetPresented) {
                    PlaylistAddSheet(track: track)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    QueueNextButton {
                        AudioPlayer.current.queueTrack(track, index: 0, playbackInfo: .init(container: nil, queueLocation: .next))
                    }
                    .tint(.orange)
                }
                .swipeActions(edge: .leading) {
                    QueueLaterButton(hideName: true) {
                        AudioPlayer.current.queueTrack(track, index: AudioPlayer.current.queue.count, playbackInfo: .init(container: nil, queueLocation: .later))
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        track.favorite.toggle()
                    } label: {
                        Label("favorite", systemImage: track.favorite ? "star.slash" : "star")
                    }
                    .tint(.orange)
                }
                .swipeActions(edge: .trailing) {
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
}

internal extension TrackListRow {
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
            releaseDate: nil)) { }
    .redacted(reason: .placeholder)
}

#Preview {
    TrackListRow.placeholder
}
