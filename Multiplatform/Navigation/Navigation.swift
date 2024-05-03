//
//  NavigationRoot+Navigation.swift
//  iOS
//
//  Created by Rasmus Krämer on 21.11.23.
//

import SwiftUI

struct Navigation {
    static let navigateNotification = NSNotification.Name("io.rfk.ampfin.navigation")
    
    static let navigateAlbumNotification = NSNotification.Name("io.rfk.ampfin.navigation.album")
    static let navigateArtistNotification = NSNotification.Name("io.rfk.ampfin.navigation.artist")
    static let navigatePlaylistNotification = NSNotification.Name("io.rfk.ampfin.navigation.playlist")
    
    static let widthChangeNotification = NSNotification.Name("io.rfk.ampfin.sidebar.width.changed")
    static let offsetChangeNotification = NSNotification.Name("io.rfk.ampfin.sidebar.offset.changed")
}

extension Navigation {
    struct NotificationModifier: ViewModifier {
        let navigateAlbum: (String) -> Void
        let navigateArtist: (String) -> Void
        let navigatePlaylist: (String) -> Void
        
        func body(content: Content) -> some View {
            content
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateArtistNotification)) { notification in
                    if let id = notification.object as? String {
                        navigateArtist(id)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateAlbumNotification)) { notification in
                    if let id = notification.object as? String {
                        navigateAlbum(id)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigatePlaylistNotification)) { notification in
                    if let id = notification.object as? String {
                        navigatePlaylist(id)
                    }
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

extension Navigation {
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
