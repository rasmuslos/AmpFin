//
//  JellyfinApi.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import UIKit

class JellyfinClient {
    private(set) var serverUrl: URL!
    private(set) var token: String!
    
    private(set) var clientVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    private(set) var clientName = UIDevice.current.name
    
    init(serverUrl: URL!, token: String? = nil) {
        self.serverUrl = serverUrl
        self.token = token
    }
    
    lazy private(set) var isAuthorized = {
        self.token != nil
    }()
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
}

// MARK: Singleton

extension JellyfinClient {
    private static func getJellyfinApiClient() -> JellyfinClient {
        JellyfinClient(serverUrl: UserDefaults.standard.url(forKey: "serverUrl"), token: UserDefaults.standard.string(forKey: "token"))
    }
    
    private(set) static var shared = getJellyfinApiClient()
}
