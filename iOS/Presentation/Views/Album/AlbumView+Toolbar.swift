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
        @Environment(\.presentationMode) var presentationMode
        @Environment(\.libraryDataProvider) var dataProvider
        @Environment(\.libraryOnline) var libraryOnline
        
        let album: Album
        let queueTracks: (_ next: Bool) -> ()
        let offlineTracker: ItemOfflineTracker
        
        @Binding var toolbarBackgroundVisible: Bool
        @Binding var imageColors: ImageColors
        
        init(album: Album, queueTracks: @escaping (_: Bool) -> Void, toolbarBackgroundVisible: Binding<Bool>, imageColors: Binding<ImageColors>) {
            self.album = album
            self.offlineTracker = album.offlineTracker
            
            self.queueTracks = queueTracks
            
            self._toolbarBackgroundVisible = toolbarBackgroundVisible
            self._imageColors = imageColors
        }
        
        func body(content: Content) -> some View {
            content
                .toolbarBackground(toolbarBackgroundVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(!toolbarBackgroundVisible)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if toolbarBackgroundVisible {
                            VStack {
                                Text(album.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                if let releaseDate = album.releaseDate {
                                    Text(String(releaseDate.get(.year)))
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
                                    .modifier(FullscreenToolbarModifier(toolbarBackgroundVisible: $toolbarBackgroundVisible, imageColors: $imageColors))
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
                        .modifier(FullscreenToolbarModifier(toolbarBackgroundVisible: $toolbarBackgroundVisible, imageColors: $imageColors))
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
                                }
                                .disabled(!dataProvider.supportsArtistLookup)
                            }
                            
                            if offlineTracker.status != .none {
                                Divider()
                                
                                Button {
                                    try? OfflineManager.shared.delete(albumId: album.id)
                                } label: {
                                    Label("download.remove.force", systemImage: "trash")
                                        .tint(.red)
                                }
                            }
                        } label: {
                            // for some reason it did show the label...
                            Image(systemName: "ellipsis")
                                .modifier(FullscreenToolbarModifier(toolbarBackgroundVisible: $toolbarBackgroundVisible, imageColors: $imageColors))
                        }
                    }
                }
        }
    }
}

// MARK: Symbol modifier

extension AlbumView {
    struct FullscreenToolbarModifier: ViewModifier {
        @Binding var toolbarBackgroundVisible: Bool
        @Binding var imageColors: ImageColors
        
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
