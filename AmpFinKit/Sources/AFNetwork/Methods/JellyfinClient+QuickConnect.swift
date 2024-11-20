//
//  JellyfinClient+QuickConnect.swift
//  AmpFin
// 
// Created by Daniel Cuevas on 9/28/24 at 1:39 AM.
//

import Foundation

public extension JellyfinClient {
    var quickConnectAvailable: Bool {
        get async {
            guard supports(.quickConnect) else {
                return false
            }
            
            return (try? await request(ClientRequest<Bool>(path: "/QuickConnect/Enabled", method: "GET"))) ?? false
        }
    }
    
    func initiateQuickConnect() async throws -> (String, String) {
        let response = try await request(ClientRequest<QuickConnectResponse>(path: "/QuickConnect/initiate", method: "POST"))
        return (response.Code, response.Secret)
    }
    
    func verifyQuickConnect(secret: String) async -> Bool {
        guard let response = try? await request(ClientRequest<QuickConnectResponse>(path: "/QuickConnect/Connect", method: "GET", query: [
            URLQueryItem(name: "Secret", value: secret),
        ])) else {
            return false
        }
        
        return response.Authenticated
    }
    
    func login(secret: String) async throws -> (String, String) {
        let response = try await request(ClientRequest<AuthenticateByNameOrQuickConnectResponse>(path: "Users/AuthenticateWithQuickConnect", method: "POST", body: [
            "Secret": secret
        ]))
        
        return (response.AccessToken, response.User.Id)
    }
}
