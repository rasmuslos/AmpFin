//
//  JellyfinApi.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import UIKit
import OSLog

class JellyfinClient {
    private(set) var serverUrl: URL!
    private(set) var token: String!
    private(set) var userId: String!
    
    private(set) var clientVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    private(set) var clientName = UIDevice.current.name
    
    let logger = Logger(subsystem: "io.rfk.music", category: "Download")
    
    init(serverUrl: URL!, token: String?, userId: String?) {
        self.serverUrl = serverUrl
        self.token = token
        self.userId = userId
    }
    
    lazy private(set) var isAuthorized = {
        self.token != nil
    }()
    public var isOnline: Bool = false {
        didSet {
            Task { @MainActor in
                NotificationCenter.default.post(name: Self.onlineStatusChanged, object: nil, userInfo: nil)
            }
        }
    }
}

// MARK: Setter

extension JellyfinClient {
    func setServerUrl(_ serverUrl: String) throws {
        guard let serverUrl = URL(string: serverUrl) else {
            throw JellyfinClientError.invalidServerUrl
        }
        
        UserDefaults.standard.set(serverUrl, forKey: "serverUrl")
        self.serverUrl = serverUrl
    }
    func setToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "token")
        self.token = token
    }
    func setUserId(_ userId: String) {
        UserDefaults.standard.set(userId, forKey: "userId")
        self.userId = userId
    }
    
    // this is a bad way of doing this, but it works
    func logout() {
        UserDefaults.standard.set(nil, forKey: "token")
        UserDefaults.standard.set(nil, forKey: "userId")
        
        exit(0)
    }
}

// MARK: Singleton

extension JellyfinClient {
    private(set) static var shared = {
        JellyfinClient(
            serverUrl: UserDefaults.standard.url(forKey: "serverUrl"),
            token: UserDefaults.standard.string(forKey: "token"),
            userId: UserDefaults.standard.string(forKey: "userId"))
    }()
}
