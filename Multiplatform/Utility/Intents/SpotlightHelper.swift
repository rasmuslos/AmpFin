//
//  SpotlightDonator.swift
//  Music
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import Defaults
import CoreSpotlight
import OSLog
import Intents
import AFBase
import AFOffline

struct SpotlightHelper {
    // 48 hours
    static let waitTime: Double = 60 * 60 * 48
    static let logger = Logger(subsystem: "io.rfk.ampfin", category: "Spotlight")
    
    static func updateIndex(force: Bool = false) {
        let isFirstDonation = Defaults[.lastSpotlightDonation] == 0 && Defaults[.lastSpotlightDonationCompletion] == 0
        let lastDonationCompleted = isFirstDonation || Defaults[.lastSpotlightDonationCompletion] > Defaults[.lastSpotlightDonation]
        let shouldSkipIndex = Defaults[.lastSpotlightDonation] + waitTime > Date.timeIntervalSinceReferenceDate && lastDonationCompleted
        
        if shouldSkipIndex {
            logger.info("Skipped spotlight indexing")
            return
        }
        
        Defaults[.lastSpotlightDonation] = Date.timeIntervalSinceReferenceDate
        
        Task.detached {
            do {
                let index = CSSearchableIndex(name: "items", protectionClass: .completeUntilFirstUserAuthentication)
                var startIndex = 0
                
                if !lastDonationCompleted, let lastData = try? await index.fetchLastClientState(), lastData.count == MemoryLayout<Int>.size {
                    startIndex = lastData.withUnsafeBytes {
                        $0.load(as: Int.self).littleEndian
                    }
                }
                if lastDonationCompleted {
                    try await index.deleteAllSearchableItems()
                }
                
                // MARK: Tracks
                
                var shouldTryMore = true
                while shouldTryMore {
                    index.beginBatch()
                    
                    let (tracks, totalTracks) = try await JellyfinClient.shared.getTracks(limit: 250, startIndex: startIndex, sortOrder: .name, ascending: true, favorite: false, search: nil, coverSize: 125)
                    var items = [CSSearchableItem]()
                    
                    startIndex += tracks.count
                    shouldTryMore = startIndex < totalTracks
                    
                    for track in tracks {
                        let attributes = CSSearchableItemAttributeSet(contentType: .audio)
                        
                        attributes.title = track.name
                        attributes.album = track.album.name
                        attributes.artist = track.artists.map { $0.name }.joined(separator: ", ")
                        attributes.album = track.album.name
                        
                        attributes.duration = NSNumber(value: track.runtime)
                        attributes.playCount = track.playCount as NSNumber
                        attributes.audioTrackNumber = NSNumber(value: track.index.disk + track.index.index)
                        
                        if let cover = track.cover, let data = try? Data(contentsOf: cover.url) {
                            attributes.thumbnailData = data
                        }
                        
                        let item = CSSearchableItem(
                            uniqueIdentifier: track.id,
                            domainIdentifier: "io.rfk.ampfin.spotlight.track",
                            attributeSet: attributes)
                        
                        items.append(item)
                    }
                    
                    if !items.isEmpty {
                        try await index.indexSearchableItems(items)
                    }
                    
                    try await index.endBatch(withClientState: withUnsafeBytes(of: startIndex.littleEndian) { Data($0) })
                    
                    // We don't need to add additional wait here as the internal processing of each batch is long enough
                }
                
                // MARK: Playlists
                
                let playlists = try await JellyfinClient.shared.getPlaylists(limit: 0, sortOrder: .name, ascending: true, favorite: false)
                if AFKIT_ENABLE_ALL_FEATURES {
                    INVocabulary.shared().setVocabularyStrings(NSOrderedSet(array: playlists.map { $0.name }), of: .mediaPlaylistTitle)
                }
                
                var items = [CSSearchableItem]()
                for playlist in playlists {
                    let attributes = CSSearchableItemAttributeSet(contentType: .audio)
                    
                    attributes.title = playlist.name
                    attributes.duration = NSNumber(value: playlist.duration)
                    
                    if let cover = playlist.cover, let data = try? Data(contentsOf: cover.url) {
                        attributes.thumbnailData = data
                    }
                    
                    let item = CSSearchableItem(
                        uniqueIdentifier: playlist.id,
                        domainIdentifier: "io.rfk.ampfin.spotlight.playlist",
                        attributeSet: attributes)
                    
                    items.append(item)
                }
                
                try await index.indexSearchableItems(items)
                
                Defaults[.lastSpotlightDonationCompletion] = Date.timeIntervalSinceReferenceDate
                Self.logger.info("Updated spotlight index")
            } catch {
                logger.fault("Failed to update spotlight index")
                print(error)
            }
        }
    }
    
    static func navigate(identifier: String) {
        Task { @MainActor in
            let albumId: String?
            
            if let track = try? OfflineManager.shared.getTrack(id: identifier) {
                albumId = track.album.id
            } else if let track = try? await JellyfinClient.shared.getTrack(id: identifier) {
                albumId = track.album.id
            } else {
                albumId = nil
            }
            
            if let albumId = albumId {
                Navigation.navigate(albumId: albumId)
            } else {
                Navigation.navigate(playlistId: identifier)
            }
        }
    }
    
    static func deleteSpotlightIndex() {
        Task {
            let index = CSSearchableIndex(name: "items", protectionClass: .completeUntilFirstUserAuthentication)
            
            try await index.deleteAllSearchableItems()
            UserDefaults.standard.removeObject(forKey: "lastSpotlightDonation")
        }
    }
}
