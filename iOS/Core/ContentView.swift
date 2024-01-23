//
//  ContentView.swift
//  Music
//
//  Created by Rasmus Krämer on 05.09.23.
//

import SwiftUI
import SwiftData
import Intents
import AFBase
import AFOffline
import AFPlayback
import CoreSpotlight

struct ContentView: View {
    @State var online = JellyfinClient.shared.isOnline
    @State var isAuthorized = JellyfinClient.shared.isAuthorized
    
    var body: some View {
        if isAuthorized {
            NavigationRoot()
                .environment(\.libraryOnline, online)
                .onContinueUserActivity(CSSearchableItemActionType, perform: SpotlightHelper.handleSpotlight)
                .onAppear {
                    SpotlightHelper.donate()
                    INMediaUserContext.donate()
                    #if ENABLE_ALL_FEATURES
                    INPreferences.requestSiriAuthorization { _ in }
                    #endif
                    
                    OfflineManager.shared.updateOfflineItems()
                    OfflineManager.shared.syncPlaysToJellyfinServer()
                    
                    JellyfinWebSocket.shared.connect()
                    AudioPlayer.current.allowRemoteControl = true
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
