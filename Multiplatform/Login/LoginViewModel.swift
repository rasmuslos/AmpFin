//
//  LoginViewModel.swift
//  AmpFin
//
//  Created by Rasmus Krämer on 16.11.24.
//

import Foundation
import SwiftUI
import AmpFinKit

extension LoginView {
    @Observable
    final class LoginViewModel {
        @MainActor var sheetPresented: Bool
        @MainActor var flowStep: LoginFlowStep
        
        @MainActor var server: String
        @MainActor var username: String
        @MainActor var password: String
        @MainActor var quickConnectAvailable: Bool?
        
        @MainActor var serverVersion: String?
        @MainActor var loginError: LoginError?
        
        @MainActor var quickConnectCode: String?
        @MainActor var quickConnectSecret: String?
        
        @MainActor var quickConnectFailed: Bool
        var quickConnectUpdateTask: Task<Void, Never>?
        
        @MainActor
        init() {
            sheetPresented = false
            flowStep = .server
            
            server = JellyfinClient.shared.serverUrl?.absoluteString ?? "https://"
            username = ""
            password = ""
            
            quickConnectAvailable = nil
            quickConnectFailed = false
            
            serverVersion = nil
            loginError = nil
        }
    }
}

extension LoginView.LoginViewModel {
    func proceed() {
        Task {
            if await flowStep == .server {
                await MainActor.run {
                    flowStep = .serverLoading
                }
                
                // Verify url format
                
                do {
                    try await JellyfinClient.shared.store(serverUrl: server)
                } catch {
                    await MainActor.run {
                        loginError = .url
                        flowStep = .server
                    }
                    
                    return
                }
                
                // Verify server
                
                do {
                    await (serverVersion, _, quickConnectAvailable) = (try await JellyfinClient.shared.serverVersion(),
                                                                       try await JellyfinClient.shared.updateCachedServerVersion(),
                                                                       await JellyfinClient.shared.quickConnectAvailable)
                } catch {
                    await MainActor.run {
                        loginError = .server
                        flowStep = .server
                    }
                    
                    return
                }
                
                await MainActor.run {
                    loginError = nil
                    flowStep = .credentials
                }
            } else if await flowStep == .credentials {
                await MainActor.run {
                    flowStep = .credentialsLoading
                }
                
                do {
                    let (token, userId) = try await JellyfinClient.shared.login(username: username, password: password)
                    
                    JellyfinClient.shared.store(token: token)
                    JellyfinClient.shared.store(userId: userId)
                } catch {
                    await MainActor.run {
                        loginError = .failed
                        flowStep = .credentials
                    }
                }
            }
        }
    }
    
    func initiateQuickConnect() async {
        await MainActor.withAnimation {
            self.quickConnectFailed = false
        }
        
        guard let (code, secret) = try? await JellyfinClient.shared.initiateQuickConnect() else {
            await MainActor.withAnimation {
                self.quickConnectFailed = true
            }
            
            return
        }
        
        await MainActor.withAnimation {
            self.quickConnectCode = code
            self.quickConnectSecret = secret
        }
    }
    func waitForQuickConnectUpdate() {
        quickConnectUpdateTask = .detached {
            repeat {
                guard let secret = await self.quickConnectSecret,
                await JellyfinClient.shared.verifyQuickConnect(secret: secret) else {
                    try? await Task.sleep(for: .seconds(1))
                    continue
                }
                
                do {
                    let (token, userId) = try await JellyfinClient.shared.login(secret: secret)
                    
                    JellyfinClient.shared.store(token: token)
                    JellyfinClient.shared.store(userId: userId)
                } catch {
                    await MainActor.withAnimation {
                        self.quickConnectFailed = true
                    }
                }
                
                self.stopWaitForQuickConnectUpdate()
            } while !Task.isCancelled
        }
    }
    func stopWaitForQuickConnectUpdate() {
        quickConnectUpdateTask = nil
    }
    
    enum LoginFlowStep {
        case server
        case serverLoading
        case credentials
        case credentialsLoading
    }
    enum LoginError {
        case server
        case url
        case failed
    }
}
