//
//  PlaylistAddSheet.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.01.24.
//

import SwiftUI
import AFBase

struct PlaylistAddSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.libraryOnline) var libraryOnline
    @Environment(\.colorScheme) var colorScheme
    
    let track: Track
    
    @State private var creatingNewPlaylist = false
    @State private var newPlaylistName = ""
    
    @State private var failed = false
    @State private var working = false
    
    @State private var playlists: [Playlist]?
    
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
                                            working = true
                                            
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
                                                working = true
                                                
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
                    .disabled(working)
                } else {
                    ErrorView()
                }
            }
            .navigationTitle("playlist.add.title")
            #if targetEnvironment(macCatalyst)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("done")
                    }
                }
            }
            #endif
            .toolbarTitleDisplayMode(.inline)
        }
        .foregroundStyle(colorScheme == .dark ? .white : .black)
        // This indicator does nothing on macOS and will only confuse our user
        #if !targetEnvironment(macCatalyst)
        .presentationDragIndicator(.visible)
        #endif
    }
}

#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            PlaylistAddSheet(track: Track.fixture)
        }
}
