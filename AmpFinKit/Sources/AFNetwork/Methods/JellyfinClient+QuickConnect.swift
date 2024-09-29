//
//  JellyfinClient+QuickConnect.swift
//  AmpFin
// 
// Created by Daniel Cuevas on 9/28/24 at 1:39 AM.
// 
    

import Foundation

public extension JellyfinClient {
    func checkIfQuickConnectIsAvailable() async throws -> Bool {
        if !JellyfinClient.shared.supports(.quickConnect) {
            return false
        }
        let response = try await request(ClientRequest<Bool>(path: "/QuickConnect/Enabled", method: "GET"))
        
        return response
    }
    
    func initiateQuickConnect() async throws -> (String, String) {
        let response = try await request(ClientRequest<QuickConnectResponse>(path: "/QuickConnect/initiate", method: "POST"))
        
        return (
            response.Code,
            response.Secret
        )
    }
    
    func verifyQuickConnect(secret: String) async throws -> Bool {
        let response = try await request(ClientRequest<QuickConnectResponse>(path: "/QuickConnect/Connect", method: "GET", query:[
            URLQueryItem(name: "Secret", value: secret)
        ]))
        
        return response.Authenticated
    }
}
