//
//  AlbumView+Toolbar.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AmpFinKit

extension AlbumView {
    struct ToolbarModifier: ViewModifier {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.isPresented) private var isPresented
        @Environment(\.libraryDataProvider) private var dataProvider
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        let album: Album
        
        let imageColors: ImageColors
        var toolbarBackgroundVisible: Bool
        
        let queueTracks: (_ next: Bool) -> ()
        
        @State private var offlineTracker: ItemOfflineTracker?
        
        private var regularPresentation: Bool {
            horizontalSizeClass == .regular
        }
        private var alignment: HorizontalAlignment {
            #if os(visionOS)
            .leading
            #else
            .center
            #endif
        }
        
        func body(content: Content) -> some View {
            content
                .navigationTitle(album.name)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(!toolbarBackgroundVisible && !regularPresentation)
                .toolbarBackground(regularPresentation ? .automatic : toolbarBackgroundVisible ? .visible : .hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        if !toolbarBackgroundVisible && isPresented && !regularPresentation {
                            Button {
                                dismiss()
                            } label: {
                                Label("back", systemImage: "chevron.left")
                                    .modifier(FullscreenToolbarModifier(imageColors: imageColors, toolbarBackgroundVisible: toolbarBackgroundVisible))
                            }
                            .transition(.move(edge: .leading))
                        }
                    }
                    
                    ToolbarItem(placement: .principal) {
                        if toolbarBackgroundVisible {
                            VStack(alignment: alignment) {
                                Text(album.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                if let releaseDate = album.releaseDate {
                                    Text(releaseDate, style: .date)
                                        .font(.caption2)
                                        .lineLimit(1)
                                }
                            }
                        } else {
                            Text(verbatim: "")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        if let offlineTracker {
                            Button {
                                if offlineTracker.status == .none {
                                    Task {
                                        try! await OfflineManager.shared.download(album: album)
                                    }
                                } else if offlineTracker.status == .downloaded {
                                    try! OfflineManager.shared.delete(albumId: album.id)
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
                            .modifier(FullscreenToolbarModifier(imageColors: imageColors, toolbarBackgroundVisible: toolbarBackgroundVisible))
                        } else {
                            ProgressView()
                                .onAppear {
                                    offlineTracker = album.offlineTracker
                                }
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                album.favorite.toggle()
                            } label: {
                                Label("favorite", systemImage: album.favorite ? "star.fill" : "star")
                            }
                            
                            Button {
                                Task {
                                    try? await album.startInstantMix()
                                }
                            } label: {
                                Label("queue.mix", systemImage: "compass.drawing")
                            }
                            .disabled(!JellyfinClient.shared.online)
                            
                            Divider()
                            
                            Button {
                                queueTracks(true)
                            } label: {
                                Label("queue.next", systemImage: "text.line.first.and.arrowtriangle.forward")
                            }
                            Button {
                                queueTracks(false)
                            } label: {
                                Label("queue.last", systemImage: "text.line.last.and.arrowtriangle.forward")
                            }
                            
                            if let first = album.artists.first {
                                Divider()
                                
                                NavigationLink(value: .artistLoadDestination(artistId: first.id)) {
                                    Label("artist.view", systemImage: "music.mic")
                                    Text(first.name)
                                }
                                .disabled(!dataProvider.supportsArtistLookup)
                            }
                            
                            Divider()
                            
                            if let offlineTracker, offlineTracker.status != .none {
                                Button(role: .destructive) {
                                    try? OfflineManager.shared.delete(albumId: album.id)
                                } label: {
                                    Label(offlineTracker.status == .working ? "download.remove.force" : "download.remove", systemImage: "trash")
                                        .foregroundStyle(.red)
                                }
                            }
                        } label: {
                            // Label("more", systemImage: "ellipsis")
                            Image(systemName: "ellipsis")
                                .labelStyle(.iconOnly)
                                .modifier(FullscreenToolbarModifier(imageColors: imageColors, toolbarBackgroundVisible: toolbarBackgroundVisible))
                        }
                    }
                }
        }
    }
}

private struct FullscreenToolbarModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let imageColors: ImageColors
    let toolbarBackgroundVisible: Bool
    
    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content
                .symbolVariant(.circle)
        } else if toolbarBackgroundVisible {
            content
                .symbolVariant(.circle)
                .animation(.easeInOut, value: toolbarBackgroundVisible)
        } else {
            content
                .symbolVariant(.circle.fill)
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    toolbarBackgroundVisible ? Color.accentColor : imageColors.isLight ? .black : .white,
                    toolbarBackgroundVisible ? .black.opacity(0.1) : .black.opacity(0.25))
                .animation(.easeInOut, value: toolbarBackgroundVisible)
        }
    }
}

