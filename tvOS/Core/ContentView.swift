//
//  ContentView.swift
//  tvOS
//
//  Created by Rasmus Krämer on 14.01.24.
//

import SwiftUI
import AuthenticationServices

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            let controller = ASAuthorizationController(authorizationRequests: [
                ASAuthorizationPasswordProvider().createRequest()
            ])
            let delegate = Delegate()
            
            controller.delegate = delegate
            controller.performRequests()
        }
    }
}

class Delegate: NSObject, ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print(authorization)
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print(error)
    }
}

#Preview {
    ContentView()
}
