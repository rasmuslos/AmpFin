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
    let logger = Logger(subsystem: "io.rfk.music", category: "Offline")
    
    private init() {
        updateOfflineFavorites()
    }
}

// MARK: Error

extension OfflineManager {
    enum OfflineError: Error {
        case notFoundError
    }
}

// MARK: Singleton

extension OfflineManager {
    public static let shared = OfflineManager()
}
