//
//  JellyfinClient+FeatureFlags.swift
//  AmpFin
// 
// Created by Rasmus Krämer on 08.09.24 at 12:59.
// 

internal extension JellyfinClient {
    typealias ServerVersion = (major: Int, minor: Int, patch: Int)
    
    var serializedLastKnownServerVersion: String? {
        guard let serverVersion else {
            return nil
        }
        
        return "\(serverVersion.major).\(serverVersion.minor).\(serverVersion.patch)"
    }
    
    func parseServerVersion(_ version: String) -> ServerVersion? {
        let components = version.split(separator: ".")
        
        guard components.count == 3 else {
            return nil
        }
        
        guard let major = Int(components[0]), let minor = Int(components[1]), let patch = Int(components[2]) else {
            return nil
        }
        
        return (major, minor, patch)
    }
}

public extension JellyfinClient {
    func updateCachedServerVersion() async throws {
        let version = try await serverVersion()
        let parsed = parseServerVersion(version)
        
        serverVersion = parsed
        Self.defaults.set(serializedLastKnownServerVersion, forKey: "lastKnownServerVersion")
    }
    
    func supports(_ featureFlag: FeatureFlag) -> Bool {
        guard let serverVersion else {
            return false
        }
        
        switch featureFlag {
            case .sharedPlaylists, .lyrics:
                // Required 10.9+
                return serverVersion.major >= 10 && serverVersion.minor >= 9
            case .quickConnect:
                // Required 10.7+
                return serverVersion.major >= 10 && serverVersion.minor >= 7
            case .legacyQuickConnect:
                // Quick Connect before 10.9.0 used GET instead of POST
                // GET is required from 10.7.0 until 10.8.13
            return
                serverVersion.major == 10 && serverVersion.minor >= 7 && serverVersion.minor <= 8
        }
    }
    
    enum FeatureFlag: Identifiable, Hashable, Codable {
        case lyrics
        case sharedPlaylists
        case quickConnect
        case legacyQuickConnect
        
        public var id: Self {
            self
        }
    }
}
