//
//  LoginView.swift
//  Music
//
//  Created by Rasmus Krämer on 05.09.23.
//

import SwiftUI
import AmpFinKit

struct LoginView: View {
    @State private var loginSheetPresented = false
    @State private var loginFlowState: LoginFlowState = .server
    
    @State private var server = JellyfinClient.shared.serverUrl?.absoluteString ?? "https://"
    @State private var username = ""
    @State private var password = ""
    
    @State private var serverVersion: String?
    @State private var loginError: LoginError?
    
    var body: some View {
        VStack {
            Spacer()
            
            Image("Logo")
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(width: 100)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.bottom, 40)
            
            Text("login.welcome")
                .font(.headline)
            Text("login.text")
                .font(.subheadline)
            
            Button {
                loginSheetPresented.toggle()
            } label: {
                Text("login.promt")
                    .padding(.vertical, 12)
                    .padding(.horizontal, 44)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .font(.headline)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .contentShape(.hoverMenuInteraction, RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(20)
            
            Spacer()
        }
        .sheet(isPresented: $loginSheetPresented, content: {
            Group {
                switch loginFlowState {
                    case .server, .credentials:
                        Form {
                            Section {
                                if loginFlowState == .server {
                                    TextField("login.server", text: $server)
                                        .keyboardType(.URL)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                } else if loginFlowState == .credentials {
                                    TextField("login.username", text: $username)
                                    SecureField("login.password", text: $password)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                }
                                
                                Button {
                                    flowStep()
                                } label: {
                                    Text("login.next")
                                }
                            } header: {
                                if let serverVersion {
                                    Text("login.version \(serverVersion)")
                                } else {
                                    Text("login.title")
                                }
                            } footer: {
                                Group {
                                    switch loginError {
                                        case .server:
                                            Text("login.error.server")
                                        case .url:
                                            Text("login.error.url")
                                        case .failed:
                                            Text("login.error.failed")
                                        case nil:
                                            EmptyView()
                                    }
                                }
                                .foregroundStyle(.red)
                            }
                            
                            if loginFlowState == .server {
                                Section {
                                    Button {
                                        loginFlowState = .customHTTPHeaders
                                    } label: {
                                        Label("login.customHTTPHeaders", systemImage: "lock.shield.fill")
                                    }
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onSubmit(flowStep)
                    case .customHTTPHeaders:
                        NavigationStack {
                            CustomHeaderEditView() {
                                loginFlowState = .server
                            }
                        }
                    case .serverLoading, .credentialsLoading:
                        VStack {
                            ProgressView()
                            
                            Text("login.loading")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(20)
                        }
                }
            }
            .transition(.opacity)
            .animation(.smooth, value: loginFlowState)
        })
    }
}

internal extension LoginView {
    private func flowStep() {
        if loginFlowState == .server {
            loginFlowState = .serverLoading
            
            // Verify url format
            
            do {
                try JellyfinClient.shared.store(serverUrl: server)
            } catch {
                loginError = .url
                loginFlowState = .server
                
                return
            }
            
            // Verify server
            
            Task {
                do {
                    serverVersion = try await JellyfinClient.shared.serverVersion()
                } catch {
                    loginError = .server
                    loginFlowState = .server
                    
                    return
                }
                
                loginError = nil
                loginFlowState = .credentials
            }
        } else if loginFlowState == .credentials {
            loginFlowState = .credentialsLoading
            
            Task {
                do {
                    let (token, userId) = try await JellyfinClient.shared.login(username: username, password: password)
                    
                    JellyfinClient.shared.store(token: token)
                    JellyfinClient.shared.store(userId: userId)
                } catch {
                    loginError = .failed
                    loginFlowState = .credentials
                }
            }
        }
    }
    
    enum LoginFlowState {
        case server
        case serverLoading
        case credentials
        case credentialsLoading
        
        case customHTTPHeaders
    }
    enum LoginError {
        case server
        case url
        case failed
    }
}

#Preview {
    LoginView()
}
