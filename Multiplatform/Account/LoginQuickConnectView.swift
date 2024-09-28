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
    @State var code: String?
    @State var secret: String?
    @State var success: Bool = false
    @State var caughtError: Bool = false
    
    var body: some View {
        if caughtError {
            VStack {
                Text("login.quickconnect.error")
                Spacer()
            }
        }
        
        List {
            Text("login.quickconnect.description")
            
            VStack(alignment: .center) {
                HStack {
                    Spacer()
                    Text("login.quickconnect.code.title")
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    Text(code ?? "??????")
                        .font(.title)
                    Spacer()
                }
            }
            
            HStack {
                ProgressView()
                Text(success ? "login.quickconnect.success" :(code != nil ? "login.quickconnect.waiting" : "login.quickconnect.preparing"))
            }
           
            
            Button("login.quickconnect.copy", systemImage: "doc.on.doc") {
                UIPasteboard.general.string = code
            }
            .foregroundColor(.accentColor)
            .disabled(code == nil)
        }
        .interactiveDismissDisabled(success)
        .onAppear() {
            do {
                Task {
                    
                    let (Code, _, _, Secret) = try await JellyfinClient.shared.initiateQuickConnect()
                    self.code = Code
                    self.secret = Secret
                    repeat {
                        let authorized = try await JellyfinClient.shared.verifyQuickConnect(secret: secret ?? "")
                        if authorized {
                            self.success = true
                            Task {
                                do {
                                    let (token, userId) =  try await JellyfinClient.shared.loginWithQuickConnect(secret: self.secret ?? "")
                                    
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
        .navigationTitle("login.quickconnect.title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LoginQuickConnectView() {}
    }
}
