//
//  JellyfinClient+QuickConnect.swift
//  AmpFin
// 
// Created by Daniel Cuevas on 9/28/24 at 1:39 AM.
// 
    

import Foundation

public extension JellyfinClient {
    func checkIfQuickConnectIsAvailable() async throws -> Bool {
        if JellyfinClient.shared.supports(.legacyQuickConnectStatus)  {
            let response = try await request(ClientRequest<String>(path: "/QuickConnect/Status", method: "GET"))
            
            return response == "Active"
        } else if JellyfinClient.shared.supports(.quickConnect) {
            let response = try await request(ClientRequest<Bool>(path: "/QuickConnect/Enabled", method: "GET"))
            
            return response
        } else {
            return false
        }
    }
    
    func initiateQuickConnect() async throws -> (String, String) {
        var method = "POST"
        if JellyfinClient.shared.supports(.legacyQuickConnect) {
            method = "GET"
        }
        
        let response = try await request(ClientRequest<QuickConnectResponse>(path: "/QuickConnect/initiate", method: method))
        
        return (
            response.Code,
            response.Secret
        )
    }
    
    func verifyQuickConnect(secret: String) async throws -> (Bool, String?) {
        let response = try await request(ClientRequest<QuickConnectResponse>(path: "/QuickConnect/Connect", method: "GET", query:[
            URLQueryItem(name: "Secret", value: secret)
        ]))
        
        return (response.Authenticated, response.Authentication)
    }
}
