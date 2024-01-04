//
//  PlaylistAddSheet.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.01.24.
//

import SwiftUI
import AFBaseKit

struct PlaylistAddSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.libraryOnline) var libraryOnline
    
    let track: Track
    
    @State var creatingNewPlaylist = false
    @State var newPlaylistName = ""
    
    @State var failed = false
    
    @State var playlists: [Playlist]?
    
    var body: some View {
        NavigationStack {
            Group {
                if libraryOnline {
                    List {
                        Section {
                            TrackListRow(track: track, startPlayback: {}, disableMenu: true)
                            
                            if failed {
                                Label("playlist.add.error", systemImage: "xmark.circle")
                                    .foregroundStyle(.red)
                            }
                        }
                        
                        Section {
                            if creatingNewPlaylist {
                                TextField("playlist.new.name", text: $newPlaylistName)
                                
                                Button {
                                    Task {
                                        do {
                                            try await JellyfinClient.shared.create(playlistName: newPlaylistName, trackIds: [track.id])
                                            dismiss()
                                        } catch {
                                            failed = true
                                        }
                                    }
                                } label: {
                                    Text("playlist.new.create")
                                }
                            } else {
                                Button {
                                    withAnimation {
                                        creatingNewPlaylist.toggle()
                                    }
                                } label: {
                                    Label("playlist.new", systemImage: "plus")
                                }
                            }
                        }
                        
                        Section {
                            if let playlists = playlists {
                                ForEach(playlists) { playlist in
                                    Button {
                                        Task {
                                            do {
                                                try await playlist.add(trackIds: [track.id])
                                                dismiss()
                                            } catch {
                                                failed = true
                                            }
                                        }
                                    } label: {
                                        PlaylistListRow(playlist: playlist)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                ProgressView()
                                    .onAppear {
                                        Task {
                                            do {
                                                playlists = try await JellyfinClient.shared.getPlaylists(limit: 0, sortOrder: .added, ascending: false, favorite: false)
                                            } catch {
                                                failed = true
                                            }
                                        }
                                    }
                            }
                        }
                    }
                } else {
                    ErrorView()
                }
            }
            .navigationTitle("playlist.add.title")
            .toolbarTitleDisplayMode(.inline)
        }
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            PlaylistAddSheet(track: Track.fixture)
        }
}
