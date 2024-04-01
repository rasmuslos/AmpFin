//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 25.12.23.
//

import Foundation

public extension JellyfinClient {
    /// Get the current version of the Jellyfin server
    func getServerPublicVersion() async throws -> String {
        let response = try await request(ClientRequest<PublicServerInfoResponse>(path: "system/info/public", method: "GET"))
        return response.Version
    }
    
    /// Login using the users username and password
    func login(username: String, password: String) async throws -> (String, String) {
        let response = try await request(ClientRequest<AuthenticateByNameResponse>(path: "Users/authenticatebyname", method: "POST", body: [
            "Username": username,
            "Pw": password,
        ]))
        
        return (response.AccessToken, response.User.Id)
    }
    
    /// Get information about the current user
    func getUserData() async throws -> (String, String, String, Bool) {
        let response = try await request(ClientRequest<UserDataResponse>(path: "Users/\(userId!)", method: "GET"))
        
        return (
            response.Name,
            response.ServerId,
            response.Id,
            response.HasPassword
        )
    }
}
