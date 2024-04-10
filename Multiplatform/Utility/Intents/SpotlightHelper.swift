//
//  SpotlightDonator.swift
//  Music
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import CoreSpotlight
import OSLog
import Intents
import AFBase
import AFOffline

struct SpotlightHelper {
    // 48 hours
    static let waitTime: Double = 60 * 60 * 48
    static let logger = Logger(subsystem: "io.rfk.ampfin", category: "Spotlight")
    
    static func donate(force: Bool = false) {
        let lastDonation = UserDefaults.standard.double(forKey: "lastSpotlightDonation")
        if lastDonation + waitTime > Date.timeIntervalSinceReferenceDate {
            logger.info("Skipped spotlight indexing")
            return
        }
        
        UserDefaults.standard.set(Date.timeIntervalSinceReferenceDate, forKey: "lastSpotlightDonation")
        
        Task.detached {
            do {
                let index = CSSearchableIndex(name: "items", protectionClass: .completeUntilFirstUserAuthentication)
                let tracks = try await JellyfinClient.shared.getTracks(limit: 0, startIndex: 0, sortOrder: .name, ascending: true, favorite: false, search: nil).0
                var items = [CSSearchableItem]()
                
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
                    try await index.deleteAllSearchableItems()
                    try await index.indexSearchableItems(items)
                }
                
                let playlists = try await JellyfinClient.shared.getPlaylists(limit: 0, sortOrder: .name, ascending: true, favorite: false)
                INVocabulary.shared().setVocabularyStrings(NSOrderedSet(array: playlists.map { $0.name }), of: .mediaPlaylistTitle)
                
                Self.logger.info("Updated spotlight index")
            } catch {
                logger.fault("Failed to update spotlight index")
                print(error)
            }
        }
    }
    static func handleSpotlight(activity: NSUserActivity) {
        guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            logger.error("Received spotlight activity without identifier")
            return
        }
        
        Task { @MainActor in
            let albumId: String
            
            if let track = try? OfflineManager.shared.getTrack(id: identifier) {
                albumId = track.album.id
            } else if let track = try? await JellyfinClient.shared.getTrack(id: identifier) {
                albumId = track.album.id
            } else {
                logger.error("Unknown trackId \(identifier)")
                return
            }
            
            NotificationCenter.default.post(name: Navigation.navigateAlbumNotification, object: albumId)
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
