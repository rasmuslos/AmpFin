//
//  SpotlightDonator.swift
//  Music
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import CoreSpotlight
import OSLog

struct SpotlightDonator {
    // 12 hours
    static let waitTime: Double = 60 * 60 * 12
    static let logger = Logger(subsystem: "io.rfk.music", category: "Spotlight")
    
    static func donate(force: Bool = false) {
        let lastDonation = UserDefaults.standard.double(forKey: "lastSpotlightDonation")
        if lastDonation + waitTime > Date.timeIntervalSinceReferenceDate {
            logger.info("Skipped spotlight indexing")
            return
        }
        
        let index = CSSearchableIndex(name: "tracks", protectionClass: .completeUntilFirstUserAuthentication)
        
        Task.detached {
            if let tracks = try? await JellyfinClient.shared.getAllTracks(sortOrder: .album, ascending: false) {
                logger.info("Indexing \(tracks.count) tracks")
                var items = [CSSearchableItem]()
                
                for track in tracks {
                    let attributes = CSSearchableItemAttributeSet(contentType: .audio)
                    attributes.title = track.name
                    attributes.artist = track.artists.map { $0.name }.joined(separator: ", ")
                    attributes.album = track.album.name
                    attributes.playCount = track.playCount as NSNumber
                    
                    let item = CSSearchableItem(uniqueIdentifier: track.id, domainIdentifier: "tracks", attributeSet: attributes)
                    items.append(item)
                }
                
                do {
                    try await index.indexSearchableItems(items)
                } catch {
                    logger.fault("Failed to index spotlight items: \(error.localizedDescription)")
                }
                
                UserDefaults.standard.set(Date.timeIntervalSinceReferenceDate, forKey: "lastSpotlightDonation")
                logger.info("Finished spotlight indexing")
            } else {
                logger.error("Could not load tracks for spotlight indexing")
            }
        }
    }
}
