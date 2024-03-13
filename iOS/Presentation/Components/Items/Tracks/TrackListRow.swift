//
//  TrackListRow.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AFBase
import AFPlayback

struct TrackListRow: View {
    let track: Track
    var album: Album? = nil
    
    var deleteCallback: TrackList.DeleteCallback = nil
    let startPlayback: () -> ()
    
    var disableMenu: Bool = false
    
    @State var addToPlaylistSheetPresented = false
    
    var body: some View {
        let size: CGFloat = album == nil ? 50 : 23
        let showArtist = album == nil || !track.artists.elementsEqual(album!.artists) { $0.id == $1.id }
        
        HStack {
            Button {
                startPlayback()
            } label: {
                PlaybackIndicator(track: track) {
                    if album != nil {
                        Text(String(track.index.index))
                            .fontDesign(.rounded)
                            .bold(track.favorite)
                    } else {
                        ItemImage(cover: track.cover)
                    }
                }
                .frame(width: size, height: size)
                .id(track.id)
                
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
            .buttonStyle(.plain)
            
            DownloadIndicator(item: track)
            
            if !disableMenu {
                Menu {
                    TrackMenu(track: track, album: album, deleteCallback: deleteCallback, addToPlaylistSheetPresented: $addToPlaylistSheetPresented)
                } label: {
                    Image(systemName: "ellipsis")
                        .renderingMode(.original)
                        .foregroundStyle(Color(UIColor.label))
                        .padding(.vertical, 10)
                        .padding(.leading, 0)
                }
                .popoverTip(InstantMixTip())
            }
        }
        .draggable(track) {
            TrackPreview(track: track)
                .padding(4)
        }
        .contextMenu {
            TrackMenu(track: track, album: album, deleteCallback: deleteCallback, addToPlaylistSheetPresented: $addToPlaylistSheetPresented)
        } preview: {
            TrackPreview(track: track)
                .padding()
                .clipShape(RoundedRectangle(cornerRadius: 15))
        }
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
        }
    }
    
    struct TrackMenu: View {
        @Environment(\.libraryDataProvider) var dataProvider
        @Environment(\.libraryOnline) var libraryOnline
        
        let track: Track
        let album: Album?
        
        let deleteCallback: TrackList.DeleteCallback
        
        @Binding var addToPlaylistSheetPresented: Bool
        
        var body: some View {
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
            .disabled(!libraryOnline)
            
            Button {
                addToPlaylistSheetPresented.toggle()
            } label: {
                Label("playlist.add", systemImage: "plus")
            }
            .disabled(!libraryOnline)
            
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
        }
    }
    
    struct PlayNextButton: View {
        let track: Track
        
        var body: some View {
            Button {
                AudioPlayer.current.queueTrack(track, index: 0)
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
                AudioPlayer.current.queueTrack(track, index: AudioPlayer.current.queue.count)
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
                Label("favorite", systemImage: track.favorite ? "heart.fill" : "heart")
            }
            .tint(.orange)
        }
    }
}
