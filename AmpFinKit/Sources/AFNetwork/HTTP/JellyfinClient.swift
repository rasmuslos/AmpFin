//
//  JellyfinApi.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import AFFoundation
import SwiftUI
import OSLog

@Observable
public final class JellyfinClient {
    public private(set) var serverUrl: URL!
    public private(set) var _token: String!
    public private(set) var _userId: String!
    
    public private(set) var clientId: String
    
    public let clientBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    public let clientVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    
    #if os(iOS)
    public let deviceType = "iOS"
    #elseif os(macOS) || targetEnvironment(macCatalyst)
    public let deviceType = "macOS"
    #else
    public let deviceType = "unknown"
    #endif
    
    let logger = Logger(subsystem: "io.rfk.ampfin", category: "HTTP")
    static let defaults = AFKIT_ENABLE_ALL_FEATURES ? UserDefaults(suiteName: "group.io.rfk.ampfin")! : UserDefaults.standard
    
    private init(serverUrl: URL!, token: String?, userId: String?) {
        if !AFKIT_ENABLE_ALL_FEATURES {
            logger.warning("User data will not be stored in an app group")
        }
        
        self.serverUrl = serverUrl
        _token = token
        _userId = userId
        
        if let clientId = Self.defaults.string(forKey: "clientId") {
            self.clientId = clientId
        } else {
            clientId = String(length: 100)
            Self.defaults.set(clientId, forKey: "clientId")
        }
    }
    
    public var online: Bool = false
}

public extension JellyfinClient {
    var authorized: Bool {
        get {
            _token != nil
        }
    }
    
    var token: String {
        get {
            _token ?? ""
        }
    }
    var userId: String {
        get {
            _userId ?? ""
        }
    }
}

public extension JellyfinClient {
    func store(serverUrl: String) throws {
        guard let serverUrl = URL(string: serverUrl) else {
            throw ClientError.invalidServerUrl
        }
        
        Self.defaults.set(serverUrl, forKey: "serverUrl")
        self.serverUrl = serverUrl
    }
    
    func store(token: String?) {
        Self.defaults.set(token, forKey: "token")
        _token = token
    }
    func store(userId: String?) {
        Self.defaults.set(userId, forKey: "userId")
        _userId = userId
    }
    
    func logout() {
        store(token: nil)
        store(userId: nil)
    }
}

public extension JellyfinClient {
    static let shared = JellyfinClient(
        serverUrl: defaults.url(forKey: "serverUrl"),
        token: defaults.string(forKey: "token"),
        userId: defaults.string(forKey: "userId"))
}
