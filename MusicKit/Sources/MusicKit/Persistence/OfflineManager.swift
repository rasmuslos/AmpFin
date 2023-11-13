//
//  OfflineManager.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData

public struct OfflineManager {
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
