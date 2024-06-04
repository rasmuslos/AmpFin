//
//  OfflineManager.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData
import OSLog

public struct OfflineManager {
    static let logger = Logger(subsystem: "io.rfk.ampfin", category: "Offline")
    
    public static let itemDownloadStatusChanged = Notification.Name.init("io.rfk.ampfin.download.updated")
    
    private init() {}
    
    @MainActor
    public func cache(position: Double, trackId: String) {
        let play = OfflinePlay(trackIdentifier: trackId, position: position, date: Date())
        PersistenceManager.shared.modelContainer.mainContext.insert(play)
    }
}

internal extension OfflineManager {
    enum OfflineError: Error {
        case notFound
    }
}

public extension OfflineManager {
    static let shared = OfflineManager()
}
