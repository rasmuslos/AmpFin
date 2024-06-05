//
//  NavigationRoot+Navigation.swift
//  iOS
//
//  Created by Rasmus Krämer on 21.11.23.
//

import SwiftUI
import AmpFinKit

internal struct Navigation {
    static let navigateNotification = NSNotification.Name("io.rfk.ampfin.navigation")
    
    static let navigateAlbumNotification = NSNotification.Name("io.rfk.ampfin.navigation.album")
    static let navigateArtistNotification = NSNotification.Name("io.rfk.ampfin.navigation.artist")
    static let navigatePlaylistNotification = NSNotification.Name("io.rfk.ampfin.navigation.playlist")
}

internal extension Navigation {
    static func navigate(albumId: String) {
        NotificationCenter.default.post(name: Self.navigateAlbumNotification, object: albumId)
    }
    static func navigate(artistId: String) {
        NotificationCenter.default.post(name: Self.navigateArtistNotification, object: artistId)
    }
    static func navigate(playlistId: String) {
        NotificationCenter.default.post(name: Self.navigatePlaylistNotification, object: playlistId)
    }
}

internal extension Navigation {
    struct NotificationModifier: ViewModifier {
        let navigateAlbum: (String) -> Void
        let navigateArtist: (String) -> Void
        let navigatePlaylist: (String) -> Void
        
        func body(content: Content) -> some View {
            content
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateAlbumNotification)) { notification in
                    guard let id = notification.object as? String else {
                        return
                    }
                    
                    navigateAlbum(id)
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateArtistNotification)) { notification in
                    guard let id = notification.object as? String else {
                        return
                    }
                    
                    navigateArtist(id)
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigatePlaylistNotification)) { notification in
                    guard let id = notification.object as? String else {
                        return
                    }
                    navigatePlaylist(id)
                }
        }
    }
    
    struct NavigationModifier: ViewModifier {
        let didNavigate: () -> Void
        
        func body(content: Content) -> some View {
            content
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateArtistNotification)) { _ in
                    didNavigate()
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateAlbumNotification)) { _ in
                    didNavigate()
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigatePlaylistNotification)) { _ in
                    didNavigate()
                }
        }
    }
    
    struct DestinationModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .navigationDestination(for: Navigation.AlbumLoadDestination.self) {
                    AlbumLoadView(albumId: $0.albumId)
                }
                .navigationDestination(for: Navigation.ArtistLoadDestination.self) {
                    ArtistLoadView(artistId: $0.artistId)
                }
                .navigationDestination(for: Navigation.PlaylistLoadDestination.self) {
                    PlaylistLoadView(playlistId: $0.playlistId)
                }
                .navigationDestination(for: TracksDestination.self) {
                    TracksView(favoritesOnly: $0.favoriteOnly)
                }
                .navigationDestination(for: AlbumsDestination.self) { _ in
                    AlbumsView()
                }
                .navigationDestination(for: PlaylistsDestination.self) { _ in
                    PlaylistsView()
                }
                .navigationDestination(for: ArtistsDestination.self) {
                    ArtistsView(albumOnly: $0.albumOnly)
                }
                .navigationDestination(for: Album.self) {
                    AlbumView(album: $0)
                }
                .navigationDestination(for: Artist.self) {
                    ArtistView(artist: $0)
                }
                .navigationDestination(for: Playlist.self) {
                    PlaylistView(playlist: $0)
                }
        }
    }
}

internal extension Navigation {
    struct AlbumLoadDestination: Hashable {
        let albumId: String
    }
    
    struct ArtistLoadDestination: Hashable {
        let artistId: String
    }
    
    struct PlaylistLoadDestination: Hashable {
        let playlistId: String
    }
    
    struct TracksDestination: Hashable {
        let favoriteOnly: Bool
    }
    struct AlbumsDestination: Hashable {
    }
    struct PlaylistsDestination: Hashable {
    }
    struct ArtistsDestination: Hashable {
        let albumOnly: Bool
    }
}

internal extension Hashable {
    static func albumLoadDestination(albumId: String) -> Navigation.AlbumLoadDestination {
        .init(albumId: albumId)
    }
    static func artistLoadDestination(artistId: String) -> Navigation.ArtistLoadDestination {
        .init(artistId: artistId)
    }
    static func playlistLoadDestination(playlistId: String) -> Navigation.PlaylistLoadDestination {
        .init(playlistId: playlistId)
    }
    
    static func tracksDestination(favoriteOnly: Bool) -> Navigation.TracksDestination {
        .init(favoriteOnly: favoriteOnly)
    }
    static var albumsDestination: Navigation.AlbumsDestination {
        .init()
    }
    static var playlistsDestination: Navigation.PlaylistsDestination {
        .init()
    }
    static func artistsDestination(albumOnly: Bool) -> Navigation.ArtistsDestination {
        .init(albumOnly: albumOnly)
    }
}
