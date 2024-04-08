//
//  AlbumView+Toolbar.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AFBase
import AFOffline

extension AlbumView {
    struct ToolbarModifier: ViewModifier {
        @Environment(\.presentationMode) private var presentationMode
        @Environment(\.libraryDataProvider) private var dataProvider
        @Environment(\.libraryOnline) private var libraryOnline
        
        let album: Album
        let offlineTracker: ItemOfflineTracker
        
        let imageColors: ImageColors
        let toolbarBackgroundVisible: Bool
        
        let queueTracks: (_ next: Bool) -> ()
        
        init(album: Album, imageColors: ImageColors, toolbarBackgroundVisible: Bool, queueTracks: @escaping (_: Bool) -> Void) {
            self.album = album
            self.offlineTracker = album.offlineTracker
            
            self.imageColors = imageColors
            self.toolbarBackgroundVisible = toolbarBackgroundVisible
            
            self.queueTracks = queueTracks
        }
        
        func body(content: Content) -> some View {
            content
                .navigationTitle(album.name)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(!toolbarBackgroundVisible)
                .toolbarBackground(toolbarBackgroundVisible ? .visible : .hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if toolbarBackgroundVisible {
                            VStack {
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
                }
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        if !toolbarBackgroundVisible && presentationMode.wrappedValue.isPresented {
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .modifier(FullscreenToolbarModifier(imageColors: imageColors, toolbarBackgroundVisible: toolbarBackgroundVisible))
                            }
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
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
                                    // and for some other reason this was blue when i used a label
                                    Image(systemName: "arrow.down")
                                case .working:
                                    ProgressView()
                                case .downloaded:
                                    Image(systemName: "xmark")
                            }
                        }
                        // funny thing, this crashed the app
                        // .popoverTip(DownloadTip())
                        .modifier(FullscreenToolbarModifier(imageColors: imageColors, toolbarBackgroundVisible: toolbarBackgroundVisible))
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                Task {
                                    await album.setFavorite(favorite: !album.favorite)
                                }
                            } label: {
                                Label("favorite", systemImage: album.favorite ? "heart.fill" : "heart")
                            }
                            
                            Button {
                                Task {
                                    try? await album.startInstantMix()
                                }
                            } label: {
                                Label("queue.mix", systemImage: "compass.drawing")
                            }
                            .disabled(!libraryOnline)
                            
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
                                
                                NavigationLink(destination: ArtistLoadView(artistId: first.id)) {
                                    Label("artist.view", systemImage: "music.mic")
                                    Text(first.name)
                                }
                                .disabled(!dataProvider.supportsArtistLookup)
                            }
                            
                            if offlineTracker.status != .none {
                                Divider()
                                
                                Button(role: .destructive) {
                                    try? OfflineManager.shared.delete(albumId: album.id)
                                } label: {
                                    Label("download.remove.force", systemImage: "trash")
                                        .foregroundStyle(.red)
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .labelStyle(.iconOnly)
                                .modifier(FullscreenToolbarModifier(imageColors: imageColors, toolbarBackgroundVisible: toolbarBackgroundVisible))
                        }
                    }
                }
        }
    }
}

// MARK: Symbol modifier

extension AlbumView {
    struct FullscreenToolbarModifier: ViewModifier {
        var imageColors: ImageColors
        var toolbarBackgroundVisible: Bool
        
        func body(content: Content) -> some View {
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
