//
//  AlbumViewModel.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.07.24.
//

import Foundation
import SwiftUI
import AmpFinKit
import AFPlayback

@Observable
internal final class AlbumViewModel {
    @MainActor let album: Album
    @MainActor private(set) var tracks: [Track]
    
    @MainActor var dataProvider: LibraryDataProvider!
    
    @MainActor private(set) var similarAlbums: [Album]
    @MainActor private(set) var albumsReleasedSameArtist: [Album]
    
    @MainActor private(set) var buttonColor: Color
    @MainActor var toolbarBackgroundVisible: Bool
    
    @MainActor private(set) var errorFeedback: Bool
    @MainActor private let offlineTracker: ItemOfflineTracker
    
    @MainActor
    init(_ album: Album) {
        self.album = album
        tracks = []
        
        similarAlbums = []
        albumsReleasedSameArtist = []
        
        buttonColor = .accentColor
        toolbarBackgroundVisible = false
        
        errorFeedback = false
        offlineTracker = album.offlineTracker
    }
}

internal extension AlbumViewModel {
    func play(shuffled: Bool) {
        Task {
            if await tracks.isEmpty {
                await fetchTracks()
            }
            
            await AudioPlayer.current.startPlayback(tracks: tracks.sorted { $0.index < $1.index }, startIndex: 0, shuffle: shuffled, playbackInfo: .init(container: album))
        }
    }
    func queue(now: Bool) {
        Task {
            if await tracks.isEmpty {
                await fetchTracks()
            }
            
            await AudioPlayer.current.queue(tracks, after: now ? 0 : AudioPlayer.current.queue.count, playbackInfo: .init(container: album))
        }
    }
    func instantMix() {
        Task {
            do {
                try await album.startInstantMix()
            } catch {
                await MainActor.run {
                    self.errorFeedback.toggle()
                }
            }
        }
    }
}

internal extension AlbumViewModel {
    func download() {
        Task {
            do {
                try await OfflineManager.shared.download(album: album)
            } catch {
                await MainActor.run {
                    self.errorFeedback.toggle()
                }
            }
        }
    }
    func evict() {
        Task {
            do {
                try OfflineManager.shared.delete(albumId: await album.id)
            } catch {
                await MainActor.run {
                    errorFeedback.toggle()
                }
            }
        }
    }
}

extension AlbumViewModel {
    internal func load() async {
        await withTaskGroup(of: Void.self) {
            $0.addTask { await self.fetchTracks() }
            $0.addTask { await self.determineButtonColor() }
            
            $0.addTask { await self.fetchSimilarAlbums() }
            $0.addTask { await self.fetchAlbumsReleasedSameArtist() }
        }
    }
    
    private func fetchTracks() async {
        do {
            let tracks = try await dataProvider.tracks(albumId: album.id)
            
            await MainActor.run {
                withAnimation {
                    self.tracks = tracks
                }
            }
        } catch {
            await MainActor.run {
                self.errorFeedback.toggle()
            }
        }
    }
    private func fetchSimilarAlbums() async {
        guard await dataProvider as? OfflineLibraryDataProvider == nil else {
            return
        }
        
        let albumId = await album.id
        
        guard let similar = try? await JellyfinClient.shared.albums(similarToAlbumId: album.id).filter({ $0.id != albumId }) else {
            return
        }
        
        await MainActor.run {
            withAnimation {
                self.similarAlbums = similar
            }
        }
    }
    func fetchAlbumsReleasedSameArtist() async {
        guard let artist = await album.artists.first else {
            return
        }
        
        let albumId = await album.id
        
        guard let albumsReleasedSameArtist = try? await dataProvider.albums(artistId: artist.id, limit: 20, startIndex: 0, sortOrder: .released, ascending: false).0.filter({ $0.id != albumId }) else {
            return
        }
        
        await MainActor.run {
            withAnimation {
                self.albumsReleasedSameArtist = albumsReleasedSameArtist
            }
        }
    }
    
    private func determineButtonColor() async {
        if let cover = await album.cover,
           let colors = try? await AFVisuals.extractDominantColors(4, cover: cover),
           let result = AFVisuals.determineSaturated(colors.map { $0.color }) {
            await MainActor.run {
                withAnimation {
                    buttonColor = result
                }
            }
        }
    }
}

internal extension AlbumViewModel {
    @MainActor
    var downloadStatus: ItemOfflineTracker.OfflineStatus {
        offlineTracker.status
    }
    
    @MainActor
    var runtime: Double {
        tracks.reduce(0, { $0 + $1.runtime })
    }
}
