//
//  SpotlightDonator.swift
//  Music
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import CoreSpotlight
import OSLog
import AFBaseKit

struct SpotlightDonator {
    // 12 hours
    static let waitTime: Double = 60 * 60 * 12
    static let logger = Logger(subsystem: "io.rfk.ampfin", category: "Spotlight")
    
    static func donate(force: Bool = false) {
        let lastDonation = UserDefaults.standard.double(forKey: "lastSpotlightDonation")
        if lastDonation + waitTime > Date.timeIntervalSinceReferenceDate && false {
            logger.info("Skipped spotlight indexing")
            return
        }
        
        let index = CSSearchableIndex(name: "tracks", protectionClass: .completeUntilFirstUserAuthentication)
        index.deleteAllSearchableItems()
    }
}
