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
                        Image(systemName: "key.radiowaves.forward")
                            .font(.system(size: 160))
                            .symbolEffect(.variableColor)
                            .padding(.bottom, 40)
                        
                        Button {
                            UIPasteboard.general.string = code
                        } label: {
                            Text(code)
                                .font(.largeTitle)
                                .fontDesign(.monospaced)
                        }
                        .foregroundStyle(.primary)
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
            .navigationTitle("login.quickconnect.title")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Link("login.quickconnect.link", destination: URL(string: "https://jellyfin.org/docs/general/server/quick-connect")!)
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
