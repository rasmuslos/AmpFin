//
//  PlaylistViewModel.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 20.08.24.
//

import Foundation
import SwiftUI
import AmpFinKit
import AFPlayback

@Observable
internal class PlaylistViewModel {
    @MainActor let playlist: Playlist
    @MainActor private(set) var tracks: [Track]
    
    @MainActor var dataProvider: LibraryDataProvider!
    
    @MainActor private(set) var colors: [Color]
    @MainActor private(set) var highlighted: Color?
    
    @MainActor private(set) var _toolbarBackgroundVisible: Bool
    @MainActor var editMode: EditMode
    
    @MainActor var dismiss: Bool
    @MainActor var deleteAlertPresented: Bool
    
    @MainActor private(set) var errorFeedback: Bool
    @MainActor private let offlineTracker: ItemOfflineTracker
    
    @MainActor
    init(_ playlist: Playlist) {
        self.playlist = playlist
        tracks = []
        
        colors = []
        highlighted = nil
        
        _toolbarBackgroundVisible = false
        editMode = .inactive
        
        dismiss = false
        deleteAlertPresented = false
        
        errorFeedback = false
        offlineTracker = playlist.offlineTracker
    }
}

internal extension PlaylistViewModel {
    @MainActor
    var toolbarBackgroundVisible: Bool {
        get {
            _toolbarBackgroundVisible
        }
        set {
            withAnimation {
                _toolbarBackgroundVisible = newValue
            }
        }
    }
    
    @MainActor
    var highlights: [Color] {
        guard let highlighted else {
            return [.accentColor]
        }
        
        return [highlighted]
    }
    
    @MainActor
    var downloadStatus: ItemOfflineTracker.OfflineStatus {
        offlineTracker.status
    }
}

internal extension PlaylistViewModel {
    func play(shuffled: Bool) {
        Task {
            if await tracks.isEmpty {
                await fetchTracks()
            }
            
            await AudioPlayer.current.startPlayback(tracks: tracks, startIndex: 0, shuffle: shuffled, playbackInfo: .init(container: playlist))
        }
    }
    func queue(now: Bool) {
        Task {
            if await tracks.isEmpty {
                await fetchTracks()
            }
            
            await AudioPlayer.current.queue(tracks, after: now ? 0 : AudioPlayer.current.queue.count, playbackInfo: .init(container: playlist))
        }
    }
}

internal extension PlaylistViewModel {
    func download() {
        Task {
            do {
                try await OfflineManager.shared.download(playlist: playlist)
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
                try await OfflineManager.shared.delete(playlistId: playlist.id)
            } catch {
                await MainActor.run {
                    errorFeedback.toggle()
                }
            }
        }
    }
    
    func delete() {
        Task {
            do {
                try await JellyfinClient.shared.delete(identifier: playlist.id)
                
                await MainActor.run {
                    dismiss.toggle()
                }
            } catch {
                await MainActor.run {
                    errorFeedback.toggle()
                }
            }
        }
    }
}

internal extension PlaylistViewModel {
    func load() async {
        await withTaskGroup(of: Void.self) {
            $0.addTask { await self.fetchTracks() }
            $0.addTask { await self.extractColors() }
        }
    }
    
    func removeTrack(_ track: Track) {
        guard JellyfinClient.shared.online else {
            Task { @MainActor in
                errorFeedback.toggle()
            }
            
            return
        }
        
        Task {
            guard let index = await tracks.firstIndex(of: track) else {
                return
            }
            
            await MainActor.withAnimation {
                self.tracks.remove(at: index)
            }
            
            do {
                try await JellyfinClient.shared.remove(trackId: track.id, playlistId: playlist.id)
                
                await MainActor.withAnimation {
                    self.playlist.trackCount = self.tracks.count
                    self.playlist.duration = self.tracks.reduce(0, { $0 + $1.runtime })
                }
            } catch {
                await MainActor.withAnimation {
                    self.errorFeedback.toggle()
                    self.tracks.insert(track, at: index)
                }
            }
        }
    }
    
    func moveTrack(_ track: Track, to targetIndex: Int) {
        guard JellyfinClient.shared.online else {
            Task { @MainActor in
                errorFeedback.toggle()
            }
            
            return
        }
        
        Task {
            guard let index = await tracks.firstIndex(of: track) else {
                return
            }
            
            var targetIndex = targetIndex
            
            if index < targetIndex {
                targetIndex -= 1
            }
            
            await MainActor.withAnimation {
                self.tracks.remove(at: index)
                self.tracks.insert(track, at: targetIndex)
            }
            
            do {
                try await JellyfinClient.shared.move(trackId: track.id, index: targetIndex, playlistId: playlist.id)
            } catch {
                await MainActor.withAnimation {
                    self.errorFeedback.toggle()
                    
                    self.tracks.insert(track, at: index)
                    self.tracks.remove(at: targetIndex)
                }
            }
        }
    }
}

private extension PlaylistViewModel {
    func fetchTracks() async {
        do {
            let tracks = try await dataProvider.tracks(playlistId: playlist.id)
            
            await MainActor.withAnimation { [tracks] in
                self.tracks = tracks
            }
        } catch {
            await MainActor.run {
                errorFeedback.toggle()
            }
        }
    }
    
    func extractColors() async {
        guard let cover = await playlist.cover, let dominantColors = try? await AFVisuals.extractDominantColors(10, cover: cover) else {
            return
        }
        
        let colors = dominantColors.map { $0.color }
        let mostSaturated = AFVisuals.determineSaturated(AFVisuals.highPassFilter(colors, threshold: 0.4))
        
        await MainActor.withAnimation { [colors, mostSaturated] in
            self.colors = colors.filter { $0 != mostSaturated }
            self.highlighted = mostSaturated
        }
    }
}
