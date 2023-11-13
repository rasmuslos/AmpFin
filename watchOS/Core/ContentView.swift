//
//  ContentView.swift
//  watchOS Watch App
//
//  Created by Rasmus Krämer on 13.11.23.
//

import SwiftUI
import WatchKit
import MusicKit

struct ContentView: View {
    let connectivityModel = ConnectivityViewModel()
    
    @State var authorized = JellyfinClient.shared.isAuthorized
    
    var body: some View {
        if authorized {
            NavigationRoot()
        } else {
            ProgressView() {
                Text("login.waiting")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            /*
            .onAppear {
                try! JellyfinClient.shared.setServerUrl("http://127.0.0.1:8096")
                JellyfinClient.shared.setUserId("42b2e9298731480f8d1b29ae4d4e1d20")
                JellyfinClient.shared.setToken("bdb3ccbc43cf48628ada771fe99b75ee")
            }
             */
            // TODO: notification
        }
    }
}

#Preview {
    ContentView()
}
