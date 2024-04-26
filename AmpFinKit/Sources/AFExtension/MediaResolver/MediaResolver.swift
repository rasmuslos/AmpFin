//
//  MediaResolver.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 13.01.24.
//

import Foundation
import Intents

public final class MediaResolver {
    public enum ResolveError: Error {
        case empty
        case missing
        case notFound
    }
}

public extension MediaResolver {
    static let shared = MediaResolver()
}
