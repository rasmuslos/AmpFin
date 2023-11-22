//
//  JellyfinApi.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import UIKit
import OSLog

#if os(iOS)
import UIKit
#endif

public class JellyfinClient {
    public private(set) var serverUrl: URL!
    public private(set) var token: String!
    public private(set) var userId: String!
    
    public private(set) var clientVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    
    #if os(iOS)
    public private(set) var clientName = UIDevice.current.name
    #else
    public private(set) var clientName = "unknown"
    #endif
    
    #if os(iOS)
    public let deviceType = "iOS"
    #elseif os(watchOS)
    public let deviceType = "watchOS"
    #else
    public let deviceType = "unknown"
    #endif
    
    let logger = Logger(subsystem: "io.rfk.music", category: "Download")
    
    init(serverUrl: URL!, token: String?, userId: String?) {
        self.serverUrl = serverUrl
        self.token = token
        self.userId = userId
    }
    
    public var isOnline: Bool = false {
        didSet {
            Task { @MainActor in
                NotificationCenter.default.post(name: Self.onlineStatusChanged, object: nil, userInfo: nil)
            }
        }
    }
}

extension JellyfinClient {
    public var isAuthorized: Bool {
        get {
            self.token != nil
        }
    }
}

// MARK: Setter

extension JellyfinClient {
    public func setServerUrl(_ serverUrl: String) throws {
        guard let serverUrl = URL(string: serverUrl) else {
            throw JellyfinClientError.invalidServerUrl
        }
        
        UserDefaults.standard.set(serverUrl, forKey: "serverUrl")
        self.serverUrl = serverUrl
    }
    public func setToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "token")
        self.token = token
    }
    public func setUserId(_ userId: String) {
        UserDefaults.standard.set(userId, forKey: "userId")
        self.userId = userId
    }
    
    // this is a bad way of doing this, but it works
    public func logout() {
        UserDefaults.standard.set(nil, forKey: "token")
        UserDefaults.standard.set(nil, forKey: "userId")
        
        exit(0)
    }
}

// MARK: Singleton

extension JellyfinClient {
    public private(set) static var shared = {
        JellyfinClient(
            serverUrl: UserDefaults.standard.url(forKey: "serverUrl"),
            token: UserDefaults.standard.string(forKey: "token"),
            userId: UserDefaults.standard.string(forKey: "userId"))
    }()
}
