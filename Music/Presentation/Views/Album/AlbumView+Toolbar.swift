//
//  AlbumView+Toolbar.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI

extension AlbumView {
    struct ToolbarModifier: ViewModifier {
        @Environment(\.presentationMode) var presentationMode
        @Environment(\.libraryOnline) var libraryOnline
        
        let album: Album
        let queueTracks: (_ next: Bool) -> ()
        
        @Binding var navbarVisible: Bool
        @Binding var imageColors: ImageColors
        
        @State var downloaded = DownloadStatus.working
        
        func body(content: Content) -> some View {
            content
                .toolbarBackground(navbarVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(!navbarVisible)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if navbarVisible {
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
                            Text("")
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        if !navbarVisible && presentationMode.wrappedValue.isPresented {
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .modifier(FullscreenToolbarModifier(navbarVisible: $navbarVisible, imageColors: $imageColors))
                            }
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        HStack {
                            Button {
                                if downloaded == .none {
                                    Task {
                                        try! await OfflineManager.shared.downloadAlbum(album)
                                    }
                                } else if downloaded == .downloaded, let offlineAlbum = try? OfflineManager.shared.getOfflineAlbum(albumId: album.id) {
                                    try! OfflineManager.shared.deleteOfflineAlbum(offlineAlbum)
                                }
                            } label: {
                                switch downloaded {
                                case .none:
                                    // and for some other reason this was blue when i used a label
                                    Image(systemName: "arrow.down")
                                case .working:
                                    ProgressView()
                                case .downloaded:
                                    Image(systemName: "xmark.circle.fill")
                                }
                            }
                            .modifier(FullscreenToolbarModifier(navbarVisible: $navbarVisible, imageColors: $imageColors))
                            Menu {
                                Button {
                                    Task {
                                        try? await album.setFavorite(favorite: !album.favorite)
                                    }
                                } label: {
                                    Label("Favorite", systemImage: album.favorite ? "heart.fill" : "heart")
                                }
                                
                                if let first = album.artists.first {
                                    NavigationLink(destination: ArtistLoadView(artistId: first.id)) {
                                        Label("View artist", systemImage: "music.mic")
                                    }
                                    .disabled(!libraryOnline)
                                }
                                
                                if downloaded != .none {
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        if let offlineAlbum = try? OfflineManager.shared.getOfflineAlbum(albumId: album.id) {
                                            try! OfflineManager.shared.deleteOfflineAlbum(offlineAlbum)
                                        }
                                    } label: {
                                        Label("Force delete", systemImage: "trash.fill")
                                    }
                                }
                                
                                Divider()
                                
                                Button {
                                    queueTracks(true)
                                } label: {
                                    Label("Play next", systemImage: "text.line.first.and.arrowtriangle.forward")
                                }
                                Button {
                                    queueTracks(false)
                                } label: {
                                    Label("Play last", systemImage: "text.line.last.and.arrowtriangle.forward")
                                }
                            } label: {
                                // for some reason it did show the label...
                                Image(systemName: "ellipsis")
                                    .modifier(FullscreenToolbarModifier(navbarVisible: $navbarVisible, imageColors: $imageColors))
                            }
                        }
                    }
                }
                .task(checkDownload)
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.DownloadUpdated)) { _ in
                    Task.detached {
                        await checkDownload()
                    }
                }
        }
    }
}

// MARK: Download

extension AlbumView.ToolbarModifier {
    enum DownloadStatus {
        case none
        case working
        case downloaded
    }
    
    @Sendable
    func checkDownload() async {
        if let offlineAlbum = try? await OfflineManager.shared.getOfflineAlbum(albumId: album.id) {
            if await OfflineManager.shared.isAlbumDownloadInProgress(offlineAlbum) {
                downloaded = .working
            } else {
                downloaded = .downloaded
            }
        } else {
            downloaded = .none
        }
    }
}

// MARK: Symbol modifier

extension AlbumView {
    struct FullscreenToolbarModifier: ViewModifier {
        @Binding var navbarVisible: Bool
        @Binding var imageColors: ImageColors
        
        func body(content: Content) -> some View {
            content
                .font(.system(size: 20))
                .symbolVariant(.circle.fill)
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    navbarVisible ? Color.accentColor : imageColors.isLight ? .black : .white,
                    navbarVisible ? .black.opacity(0.1) : .black.opacity(0.25))
                .animation(.easeInOut, value: navbarVisible)
        }
    }
}
