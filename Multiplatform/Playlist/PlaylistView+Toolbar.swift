//
//  PlaylistView+Toolbar.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import SwiftUI
import AmpFinKit
import AFPlayback

extension PlaylistView {
    struct ToolbarModifier: ViewModifier {
        @Environment(\.dismiss) private var dismiss
        
        let playlist: Playlist
        
        @Binding var toolbarVisible: Bool
        
        @Binding var tracks: [Track]
        @Binding var editMode: EditMode
        
        @State private var alertPresented = false
        @State private var offlineTracker: ItemOfflineTracker?
        
        func body(content: Content) -> some View {
            content
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        if let offlineTracker {
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
                        } else {
                            ProgressView()
                                .task {
                                    offlineTracker = playlist.offlineTracker
                                }
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        if editMode == .active {
                            Button {
                                withAnimation {
                                    editMode = .inactive
                                }
                            } label: {
                                Label("done", systemImage: "checkmark")
                                    .labelStyle(.iconOnly)
                                    .modifier(FullscreenToolbarModifier(toolbarVisible: toolbarVisible))
                            }
                        } else {
                            Menu {
                                Button {
                                    playlist.favorite.toggle()
                                } label: {
                                    Label("favorite", systemImage: playlist.favorite ? "star.fill" : "star")
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
                                        editMode = .active
                                    }
                                } label: {
                                    Label("playlist.edit", systemImage: "pencil")
                                }
                                .disabled(!JellyfinClient.shared.online)
                                
                                Button(role: .destructive) {
                                    alertPresented.toggle()
                                } label: {
                                    Label("playlist.delete", systemImage: "trash")
                                }
                                .disabled(!JellyfinClient.shared.online)
                                
                                if let offlineTracker, offlineTracker.status != .none {
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        try? OfflineManager.shared.delete(playlistId: playlist.id)
                                    } label: {
                                        Label("download.remove.force", systemImage: "trash")
                                            .foregroundStyle(.red)
                                    }
                                }
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
                            try! await JellyfinClient.shared.delete(identifier: playlist.id)
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

private struct FullscreenToolbarModifier: ViewModifier {
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
