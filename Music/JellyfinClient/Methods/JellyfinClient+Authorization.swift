//
//  JellyfinClient+Methods.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

// MARK: Public Server Info

extension JellyfinClient {
    func getServerPublicVersion() async throws -> String {
        let response = try await request(ClientRequest<PublicServerInfoResponse>(path: "system/info/public", method: "GET"))
        return response.Version
    }
    
    struct PublicServerInfoResponse: Codable {
        let LocalAddress: String
        let ServerName: String
        let Version: String
        let ProductName: String
        let OperatingSystem: String
        let Id: String
        let StartupWizardCompleted: Bool
    }
}


// MARK: Login

extension JellyfinClient {
    func login(username: String, password: String) async throws -> String {
        let response = try await request(ClientRequest<AuthenticateByNameResponse>(path: "Users/authenticatebyname", method: "POST", body: [
            "Username": username,
            "Pw": password,
        ]))
        
        UserDefaults.standard.set(response.User.Id, forKey: "userId")
        return response.AccessToken
    }
    
    struct AuthenticateByNameResponse: Codable {
        let AccessToken: String
        let User: User
        
        struct User: Codable {
            let Id: String
        }
    }
}
