//
//  ContentView.swift
//  Music
//
//  Created by Rasmus Krämer on 05.09.23.
//

import SwiftUI
import SwiftData
import Intents
import AFBaseKit
import AFOfflineKit
import AFPlaybackKit

struct ContentView: View {
    @State var online = JellyfinClient.shared.isOnline
    @State var isAuthorized = JellyfinClient.shared.isAuthorized
    
    var body: some View {
        if isAuthorized {
            NavigationRoot()
                .environment(\.libraryOnline, online)
                .onAppear {
                    SpotlightDonator.donate()
                    UserContext.updateContext()
                    
                    OfflineManager.shared.updateOfflineItems()
                    OfflineManager.shared.updateOfflineFavorites()
                    OfflineManager.shared.syncPlaysToJellyfinServer()
                    
                    JellyfinWebSocket.shared.connect()
                    AudioPlayer.current.allowRemoteControl = true
                    
                    INPreferences.requestSiriAuthorization { _ in }
                }
                .onReceive(NotificationCenter.default.publisher(for: JellyfinClient.onlineStatusChanged), perform: { _ in
                    online = JellyfinClient.shared.isOnline
                })
        } else {
            LoginView() {
                isAuthorized = true
            }
        }
    }
}

#Preview {
    ContentView()
}
