//
//  NavigationRoot+Navigation.swift
//  iOS
//
//  Created by Rasmus Krämer on 21.11.23.
//

import SwiftUI

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
                .navigationDestination(for: Navigation.AlbumLoadDestination.self) { data in
                    AlbumLoadView(albumId: data.albumId)
                }
                .navigationDestination(for: Navigation.ArtistLoadDestination.self) { data in
                    ArtistLoadView(artistId: data.artistId)
                }
                .navigationDestination(for: Navigation.PlaylistLoadDestination.self) { data in
                    PlaylistLoadView(playlistId: data.playlistId)
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
}
