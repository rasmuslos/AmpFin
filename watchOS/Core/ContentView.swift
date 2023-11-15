//
//  ContentView.swift
//  watchOS Watch App
//
//  Created by Rasmus Krämer on 13.11.23.
//

import SwiftUI
import WatchKit
import MusicKit
import ConnectivityKit

struct ContentView: View {
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
            .onReceive(NotificationCenter.default.publisher(for: ConnectivityKit.authenticated), perform: { _ in
                authorized = true
            })
        }
    }
}

#Preview {
    ContentView()
}
