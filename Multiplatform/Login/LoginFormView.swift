//
//  LoginFormView.swift
//  AmpFin
//
//  Created by Rasmus Krämer on 16.11.24.
//

import SwiftUI

extension LoginView {
    struct LoginFormView: View {
        @Environment(LoginViewModel.self) private var viewModel
        
        var body: some View {
            @Bindable var viewModel = viewModel
            
            Form {
                Section {
                    if viewModel.flowStep == .server {
                        TextField("login.server", text: $viewModel.server)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } else if viewModel.flowStep == .credentials {
                        TextField("login.username", text: $viewModel.username)
                        SecureField("login.password", text: $viewModel.password)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    
                    Button {
                        viewModel.proceed()
                    } label: {
                        Text("login.next")
                    }
                } header: {
                    if let serverVersion = viewModel.serverVersion {
                        Text("login.version \(serverVersion)")
                    } else {
                        Text("login.title")
                    }
                } footer: {
                    Group {
                        switch viewModel.loginError {
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
                
                if viewModel.flowStep == .server {
                    Section {
                        NavigationLink(destination: CustomHeaderEditView()) {
                            Label("login.customHTTPHeaders", systemImage: "lock.shield.fill")
                        }
                        .foregroundStyle(.secondary)
                    }
                } else if viewModel.flowStep == .credentials {
                    Section {
                        if viewModel.quickConnectAvailable == true {
                            NavigationLink(destination: LoginQuickConnectView()) {
                                Label("login.quickConnect.title", systemImage: "numbers.rectangle")
                            }
                        } else {
                            Label("login.quickConnect.unavailable.title", systemImage: "numbers.rectangle")
                                .foregroundStyle(.secondary)
                        }
                    } footer: {
                        Text("login.quickConnect.description")
                    }
                }
            }
            .onSubmit(viewModel.proceed)
        }
    }
}
