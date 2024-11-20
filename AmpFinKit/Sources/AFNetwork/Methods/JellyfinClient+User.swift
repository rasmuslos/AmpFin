//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 25.12.23.
//

import Foundation

public extension JellyfinClient {
    func serverVersion() async throws -> String {
        let response = try await request(ClientRequest<PublicServerInfoResponse>(path: "system/info/public", method: "GET"))
        return response.Version
    }
    
    func login(username: String, password: String) async throws -> (String, String) {
        let response = try await request(ClientRequest<AuthenticateByNameOrQuickConnectResponse>(path: "Users/authenticatebyname", method: "POST", body: [
            "Username": username,
            "Pw": password,
        ]))
        
        return (response.AccessToken, response.User.Id)
    }
    
    func userData() async throws -> (String, String, String, Bool) {
        let response = try await request(ClientRequest<UserDataResponse>(path: "/Users/\(userId)", method: "GET"))
        
        return (
            response.Name,
            response.ServerId,
            response.Id,
            response.HasPassword
        )
    }
}
