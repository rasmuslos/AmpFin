//
//  LoginView.swift
//  tvOS
//
//  Created by Rasmus Krämer on 19.01.24.
//

import SwiftUI
import AFBase

struct LoginView: View {
    var callback : () -> ()
    
    @State var loginSheetPresented = false
    @State var loginFlowState: LoginFlowState = .server
    
    @State var server = JellyfinClient.shared.serverUrl?.absoluteString ?? ""
    @State var username = ""
    @State var password = ""
    
    @State var serverVersion: String?
    @State var loginError: LoginError?
    
    var body: some View {
        VStack {
            Spacer()
            
            Image("Logo")
                .resizable()
                .aspectRatio(800/480, contentMode: .fit)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(.bottom, 50)
            
            Text("login.welcome")
                .font(.headline)
            Text("login.text")
                .font(.subheadline)
            
            Button {
                loginSheetPresented.toggle()
            } label: {
                Text("login.promt")
            }
            .padding()
            
            Spacer()
        }
        .sheet(isPresented: $loginSheetPresented, content: {
            switch loginFlowState {
            case .server, .credentials:
                List {
                    Section {
                        if loginFlowState == .server {
                            TextField("login.server", text: $server)
                                .keyboardType(.URL)
                                .textFieldStyle(.plain)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else if loginFlowState == .credentials {
                            TextField("login.username", text: $username)
                                .textFieldStyle(.plain)
                            SecureField("login.password", text: $password)
                                .textFieldStyle(.plain)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        
                        Button {
                            flowStep()
                        } label: {
                            Text("login.next")
                        }
                    } header: {
                        if let serverVersion = serverVersion {
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
                                Text(verbatim: "")
                            }
                        }
                        .foregroundStyle(.red)
                    }
                }
                .onSubmit(flowStep)
            case .serverLoading, .credentialsLoading:
                VStack {
                    ProgressView()
                    Text("login.loading")
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
                loginError = .url
                loginFlowState = .server
                
                return
            }
            
            // Verify server
            Task {
                do {
                    serverVersion = try await JellyfinClient.shared.getServerPublicVersion()
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
                    
                    JellyfinClient.shared.setToken(token)
                    JellyfinClient.shared.setUserId(userId)
                    callback()
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
    }
    enum LoginError {
        case server
        case url
        case failed
    }
}

#Preview {
    LoginView() {
        print("Login flow finished")
    }
}
