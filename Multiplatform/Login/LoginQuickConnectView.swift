//
//  LoginQuickConnectView.swift
//  AmpFin
//
//  Created by Daniel Cuevas on 9/27/24.
//

import SwiftUI
import AmpFinKit

extension LoginView {
    struct LoginQuickConnectView: View {
        @Environment(LoginViewModel.self) private var viewModel
        
        var body: some View {
            Group {
                if let code = viewModel.quickConnectCode {
                    ScrollView {
                        ContentUnavailableView(String(code), systemImage: "person.wave.2", description: Text("login.quickConnect.help"))
                            .symbolEffect(.variableColor)
                            .onTapGesture {
                                UIPasteboard.general.string = code
                            }
                    }
                    .contentMargins(.top, 160)
                    .onAppear {
                        viewModel.waitForQuickConnectUpdate()
                    }
                    .onDisappear {
                        viewModel.stopWaitForQuickConnectUpdate()
                    }
                } else if viewModel.quickConnectFailed {
                    ErrorView()
                } else {
                    LoadingView()
                        .task {
                            await viewModel.initiateQuickConnect()
                        }
                }
            }
            .navigationTitle("login.quickConnect.title")
            .navigationBarTitleDisplayMode(.inline)
            .background(.background.secondary)
            .safeAreaInset(edge: .bottom) {
                Link("login.quickConnect.link", destination: URL(string: "https://jellyfin.org/docs/general/server/quick-connect")!)
            }
            .refreshable {
                await viewModel.initiateQuickConnect()
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView.LoginQuickConnectView()
    }
    .environment(LoginView.LoginViewModel())
}
