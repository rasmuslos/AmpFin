//
//  PlaylistView+Toolbar.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import SwiftUI
import AFBaseKit
import AFPlaybackKit

extension PlaylistView {
    struct ToolbarModifier: ViewModifier {
        @Environment(\.libraryOnline) var libraryOnline
        
        let playlist: Playlist
        
        @Binding var tracks: [Track]
        @Binding var editMode: EditMode
        
        @State var alertPresented = false
        
        func body(content: Content) -> some View {
            content
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            
                        } label: {
                            Image(systemName: "arrow.down.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .black.opacity(0.25))
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
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
                                AudioPlayer.current.queueTracks(tracks, index: 0)
                            } label: {
                                Label("queue.next", systemImage: "text.line.first.and.arrowtriangle.forward")
                            }
                            Button {
                                AudioPlayer.current.queueTracks(tracks, index: AudioPlayer.current.queue.count)
                            } label: {
                                Label("queue.last", systemImage: "text.line.last.and.arrowtriangle.forward")
                            }
                            
                            if libraryOnline {
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
                                
                                Button(role: .destructive) {
                                    alertPresented.toggle()
                                } label: {
                                    Label("playlist.delete", systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .black.opacity(0.25))
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
                            
                            NotificationCenter.default.post(name: NavigationRoot.navigateBackNotification, object: nil)
                        }
                    } label: {
                        Text("playlist.delete.finalize")
                    }
                }
        }
    }
}
