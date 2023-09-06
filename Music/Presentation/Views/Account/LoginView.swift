//
//  LoginView.swift
//  Music
//
//  Created by Rasmus Krämer on 05.09.23.
//

import SwiftUI

struct LoginView: View {
    var callback : () -> ()
    
    @State var loginSheetPresented = false
    @State var loginFlowState: LoginFlowState = .server
    
    @State var server = JellyfinClient.shared.serverUrl?.absoluteString ?? ""
    @State var username = ""
    @State var password = ""
    
    @State var serverVersion: String?
    @State var errorText: String?
    
    var body: some View {
        VStack {
            Image("Logo")
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(width: 100)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(.bottom, 50)
            
            Text("Welcome to Music")
                .font(.headline)
            Text("Please login to get started")
                .font(.subheadline)
            
            Button {
                loginSheetPresented.toggle()
            } label: {
                Text("Login with Jellyfin")
            }
            .buttonStyle(LargeButtonStyle())
            .padding()
        }
        .sheet(isPresented: $loginSheetPresented, content: {
            switch loginFlowState {
            case .server, .credentials:
                Form {
                    Section {
                        if loginFlowState == .server {
                            TextField("Server URL", text: $server)
                                .keyboardType(.URL)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else if loginFlowState == .credentials {
                            TextField("Username", text: $username)
                            SecureField("Password", text: $password)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        
                        Button {
                            flowStep()
                        } label: {
                            Text("Next")
                        }
                    } header: {
                        if let serverVersion = serverVersion {
                            Text("Server Version \(serverVersion)")
                        }
                    } footer: {
                        if let errorText = errorText {
                            Text(errorText)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .onSubmit(flowStep)
            case .serverLoading, .credentialsLoading:
                VStack {
                    ProgressView()
                    Text("Loading")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
        })
    }
    
    enum LoginFlowState {
        case server
        case serverLoading
        case credentials
        case credentialsLoading
    }
}

// MARK: Functions

extension LoginView {
    private func flowStep() {
        if loginFlowState == .server {
            loginFlowState = .serverLoading
            
            // Verify url format
            do {
                try JellyfinClient.shared.setServerUrl(server)
            } catch {
                errorText = "Invalid server URL (Format: http(s)://host:port)"
                loginFlowState = .server
            }
            
            // Verify server
            Task {
                do {
                    serverVersion = try await JellyfinClient.shared.getServerPublicVersion()
                } catch {
                    errorText =  "Jellyfin server not found"
                    loginFlowState = .server
                }
                
                errorText = nil
                loginFlowState = .credentials
            }
        } else if loginFlowState == .credentials {
            loginFlowState = .credentialsLoading
            
            Task {
                do {
                    let token = try await JellyfinClient.shared.login(username: username, password: password)
                    
                    JellyfinClient.shared.setToken(token)
                    callback()
                } catch {
                    errorText = "Login failed"
                    loginFlowState = .credentials
                }
            }
        }
    }
}

#Preview {
    LoginView() {
        print("Login flow finished")
    }
}
