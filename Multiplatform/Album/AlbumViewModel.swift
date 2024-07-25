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
    let album: Album
    private(set) var tracks: [Track]
    
    var dataProvider: LibraryDataProvider!
    
    private(set) var buttonColor: Color
    var toolbarBackgroundVisible: Bool
    
    private(set) var errorFeedback: Bool
    private let offlineTracker: ItemOfflineTracker
    
    init(_ album: Album) {
        self.album = album
        tracks = []
        
        buttonColor = .accentColor
        toolbarBackgroundVisible = false
        
        errorFeedback = false
        offlineTracker = album.offlineTracker
    }
    
    func toggleFavorite() {
        album.favorite.toggle()
    }
}

internal extension AlbumViewModel {
    func play(shuffled: Bool) {
        Task {
            if tracks.isEmpty {
                await fetchTracks()
            }
            
            AudioPlayer.current.startPlayback(tracks: tracks.sorted { $0.index < $1.index }, startIndex: 0, shuffle: shuffled, playbackInfo: .init(container: album))
        }
    }
    func queue(now: Bool) {
        Task {
            if tracks.isEmpty {
                await fetchTracks()
            }
            
            AudioPlayer.current.queueTracks(tracks, index: now ? 0 : AudioPlayer.current.queue.count, playbackInfo: .init(container: album))
        }
    }
    func instantMix() {
        Task {
            do {
                try await album.startInstantMix()
            } catch {
                errorFeedback.toggle()
            }
        }
    }
}

internal extension AlbumViewModel {
    func download() {
        Task.detached { [album] in
            do {
                try await OfflineManager.shared.download(album: album)
            } catch {
                self.errorFeedback.toggle()
            }
        }
    }
    func evict() {
        do {
            try OfflineManager.shared.delete(albumId: album.id)
        } catch {
            errorFeedback.toggle()
        }
    }
}

extension AlbumViewModel {
    internal func load() async {
        await withTaskGroup(of: Void.self) {
            $0.addTask { await self.fetchTracks() }
            $0.addTask { await self.determineButtonColor() }
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
            errorFeedback.toggle()
        }
    }
    private func determineButtonColor() async {
        if let cover = album.cover,
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
    
    var runtime: Double {
        tracks.reduce(0, { $0 + $1.runtime })
    }
}
