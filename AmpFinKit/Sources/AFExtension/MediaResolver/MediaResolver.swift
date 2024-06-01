//
//  MediaResolver.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 13.01.24.
//

import Foundation
import Intents

@available(macOS, unavailable)
public final class MediaResolver {
    private init() {}
    
    public enum ResolveError: Error {
        case empty
        case missing
        case notFound
    }
}

@available(macOS, unavailable)
public extension MediaResolver {
    static let shared = MediaResolver()
}
