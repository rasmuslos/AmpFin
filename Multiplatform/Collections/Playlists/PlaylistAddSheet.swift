//
//  PlaylistAddSheet.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.01.24.
//

import SwiftUI
import AmpFinKit
import Defaults

struct PlaylistAddSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    let track: Track
    
    @State private var creatingNewPlaylist = false
    @State private var newPlaylistName = ""
    // Older Jellyfin servers that don't support private playlists are set to true to avoid user confusion, otherwise it checks the user's preference
    @State private var publicPlaylist: Bool = JellyfinClient.shared.supports(.sharedPlaylists) ? !Defaults[.newPlaylistDefaultPrivate] : true 
    
    @State private var failed = false
    @State private var working = false
    
    @State private var playlists: [Playlist]?
    
    var body: some View {
        NavigationStack {
            Group {
                if JellyfinClient.shared.online {
                    List {
                        Section {
                            TrackListRow(track: track, preview: true) {}
                            
                            if failed {
                                Label("playlist.add.error", systemImage: "xmark.circle")
                                    .foregroundStyle(.red)
                            }
                        }
                        
                        Section {
                            if creatingNewPlaylist {
                                TextField("playlist.new.name", text: $newPlaylistName)
                                
                                Toggle("playlist.new.public", isOn: $publicPlaylist)
                                    .disabled(!JellyfinClient.shared.supports(.sharedPlaylists))
                                
                                Button {
                                    Task {
                                        do {
                                            working = true
                                            
                                            try await JellyfinClient.shared.create(playlistName: newPlaylistName, trackIds: [track.id], isPublic: publicPlaylist)
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
                                            .contentShape(.hoverMenuInteraction, Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                ProgressView()
                                    .task {
                                        guard let playlists = try? await JellyfinClient.shared.playlists(limit: 0, sortOrder: .lastPlayed, ascending: false) else {
                                            failed = true
                                            return
                                        }
                                        
                                        self.playlists = playlists
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
            #if targetEnvironment(macCatalyst) || os(visionOS)
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
