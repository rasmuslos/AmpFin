//
//  LoginQuickConnectView.swift
//  AmpFin
//
//  Created by Daniel Cuevas on 9/27/24.
//

import SwiftUI
import AmpFinKit

internal struct LoginQuickConnectView: View {
    let dismiss: (() -> Void)
    @State private var code: String?
    @State private var secret: String = ""
    @State private var success: Bool = false
    @State private var caughtError: Bool = false
    @State private var expired: Bool = false
    
    var body: some View {
        
        ScrollView {
            VStack {
                Spacer()
                
                if caughtError {
                    VStack {
                        Text("login.quickconnect.error")
                            .font(.caption)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                }
                
                Text(code ?? "??????")
                    .font(.largeTitle)
                    .padding(.bottom, 20)
                
                
                ProgressView()
                
                Text(success ? "login.quickconnect.success" :(code != nil ? "login.quickconnect.waiting" : "login.quickconnect.preparing"))
                    .font(.caption)
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                    .foregroundStyle(.secondary)
                
                
                Button("login.quickconnect.copy", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = code
                }
                .foregroundColor(.accentColor)
                .disabled(code == nil)
            }
            .padding(.vertical, 40)
        }
        .interactiveDismissDisabled(success)
        .onAppear() {
            Task {
                do {
                    let (Code, Secret) = try await JellyfinClient.shared.initiateQuickConnect()
                    self.code = Code
                    self.secret = Secret
                    repeat {
                        let authorized = try await JellyfinClient.shared.verifyQuickConnect(secret: self.secret)
                        if authorized {
                            self.success = true
                            Task {
                                do {
                                    let (token, userId) =  try await JellyfinClient.shared.loginWithQuickConnect(secret: self.secret)
                                    
                                    JellyfinClient.shared.store(token: token)
                                    JellyfinClient.shared.store(userId: userId)
                                } catch {
                                    caughtError = true
                                }
                            }
                            throw CancellationError()
                        }
                        
                        try? await Task.sleep(for: .seconds(5))
                    } while (!Task.isCancelled)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label("done", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                } .disabled(success)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Link("login.quickconnect.link", destination: URL(string: "https://jellyfin.org/docs/general/server/quick-connect")!)
        }
        .navigationTitle("login.quickconnect.title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LoginQuickConnectView() {}
    }
}
