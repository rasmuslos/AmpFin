//
//  PlaylistView+Toolbar.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import SwiftUI
import AFBase
import AFOffline
import AFPlayback

extension PlaylistView {
    struct ToolbarModifier: ViewModifier {
        @Environment(\.libraryOnline) private var libraryOnline
        @Environment(\.dismiss) private var dismiss
        
        let playlist: Playlist
        let offlineTracker: ItemOfflineTracker
        
        var toolbarVisible = false
        
        @Binding var tracks: [Track]
        @Binding var editMode: EditMode
        
        init(playlist: Playlist, toolbarVisible: Bool, tracks: Binding<[Track]>, editMode: Binding<EditMode>) {
            self.playlist = playlist
            offlineTracker = playlist.offlineTracker
            
            self.toolbarVisible = toolbarVisible
            
            _tracks = tracks
            _editMode = editMode
        }
        
        @State private var alertPresented = false
        
        func body(content: Content) -> some View {
            content
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if offlineTracker.status == .none {
                                Task {
                                    try! await OfflineManager.shared.download(playlist: playlist)
                                }
                            } else if offlineTracker.status == .downloaded {
                                try! OfflineManager.shared.delete(playlistId: playlist.id)
                            }
                        } label: {
                            switch offlineTracker.status {
                                case .none:
                                    Label("download", systemImage: "arrow.down")
                                        .labelStyle(.iconOnly)
                                case .working:
                                    ProgressView()
                                case .downloaded:
                                    Label("download.remove", systemImage: "xmark")
                                        .labelStyle(.iconOnly)
                            }
                        }
                        .modifier(FullscreenToolbarModifier(toolbarVisible: toolbarVisible))
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        if editMode == .active {
                            Button {
                                editMode = .inactive
                            } label: {
                                Label("done", systemImage: "checkmark")
                                    .labelStyle(.iconOnly)
                                    .modifier(FullscreenToolbarModifier(toolbarVisible: toolbarVisible))
                            }
                        } else {
                            Menu {
                                Button {
                                    Task {
                                        await playlist.setFavorite(favorite: !playlist.favorite)
                                    }
                                } label: {
                                    Label("favorite", systemImage: playlist.favorite ? "heart.fill" : "heart")
                                }
                                
                                Divider()
                                
                                Button {
                                    AudioPlayer.current.queueTracks(tracks, index: 0, playbackInfo: .init(container: playlist, queueLocation: .next))
                                } label: {
                                    Label("queue.next", systemImage: "text.line.first.and.arrowtriangle.forward")
                                }
                                Button {
                                    AudioPlayer.current.queueTracks(tracks, index: AudioPlayer.current.queue.count, playbackInfo: .init(container: playlist, queueLocation: .later))
                                } label: {
                                    Label("queue.last", systemImage: "text.line.last.and.arrowtriangle.forward")
                                }
                                
                                Divider()
                                
                                Button {
                                    withAnimation {
                                        if editMode == .active {
                                            editMode = .inactive
                                        } else {
                                            editMode = .active
                                        }
                                    }
                                } label: {
                                    Label("playlist.edit", systemImage: "pencil")
                                }
                                .disabled(!libraryOnline)
                                
                                Button(role: .destructive) {
                                    alertPresented.toggle()
                                } label: {
                                    Label("playlist.delete", systemImage: "trash")
                                }
                                .disabled(!libraryOnline)
                            } label: {
                                Image(systemName: "ellipsis")
                                    .modifier(FullscreenToolbarModifier(toolbarVisible: toolbarVisible))
                            }
                        }
                    }
                }
                .alert("playlist.delete.alert", isPresented: $alertPresented) {
                    Button(role: .cancel) {
                        alertPresented = false
                    } label: {
                        Text("cancel")
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            try! await JellyfinClient.shared.delete(itemId: playlist.id)
                            alertPresented = false
                            
                            dismiss()
                        }
                    } label: {
                        Text("playlist.delete.finalize")
                    }
                }
        }
    }
}

extension PlaylistView.ToolbarModifier {
    struct FullscreenToolbarModifier: ViewModifier {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        let toolbarVisible: Bool
        
        func body(content: Content) -> some View {
            if horizontalSizeClass == .regular {
                content
                    .symbolVariant(.circle)
            } else if toolbarVisible {
                content
                    .symbolVariant(.circle)
                    .animation(.easeInOut, value: toolbarVisible)
            } else {
                content
                    .symbolVariant(.circle.fill)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.25))
                    .animation(.easeInOut, value: toolbarVisible)
            }
        }
    }
}
