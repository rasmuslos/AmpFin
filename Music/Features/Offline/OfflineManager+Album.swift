//
//  OfflineManager+Album.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData

extension OfflineManager {
    func getAlbumTracks(_ album: OfflineAlbum) async throws -> [OfflineTrack] {
        let tracks = FetchDescriptor<OfflineTrack>(predicate: album.filterPredicate())
        return try await PersistenceManager.shared.modelContainer.mainContext.fetch(tracks)
    }
    
    func isAlbumComplete(_ album: OfflineAlbum) async -> Bool {
        let tracks = (try? await getAlbumTracks(album)) ?? []
        return album.trackCount == tracks.count
    }
    func isAlbumDownloadInProgress(_ album: OfflineAlbum) async -> Bool {
        let tracks = (try? await getAlbumTracks(album)) ?? []
        return tracks.reduce(false) { $1.isDownloaded() ? $0 : true }
    }
}
