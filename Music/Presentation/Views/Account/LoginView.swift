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
            Spacer()
            
            Image("Logo")
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(width: 100)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(.bottom, 50)
            
            Text("Welcome to AmpFin")
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
            
            Spacer()
            
            Text("Devloped by Rasmus Krämer")
                .font(.caption)
                .foregroundStyle(.secondary)
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
                        } else {
                            Text("Login")
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
                
                return
            }
            
            // Verify server
            Task {
                do {
                    serverVersion = try await JellyfinClient.shared.getServerPublicVersion()
                } catch {
                    errorText =  "Jellyfin server not found"
                    loginFlowState = .server
                    
                    return
                }
                
                errorText = nil
                loginFlowState = .credentials
            }
        } else if loginFlowState == .credentials {
            loginFlowState = .credentialsLoading
            
            Task {
                do {
                    let (token, userId) = try await JellyfinClient.shared.login(username: username, password: password)
                    
                    JellyfinClient.shared.setToken(token)
                    JellyfinClient.shared.setUserId(userId)
                    callback()
                } catch {
                    errorText = "Login failed"
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
    }
}

#Preview {
    LoginView() {
        print("Login flow finished")
    }
}
