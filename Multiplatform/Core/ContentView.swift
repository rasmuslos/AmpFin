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
import Network

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var online = JellyfinClient.shared.isOnline
    @State private var authorized = JellyfinClient.shared.isAuthorized
    
    private var navigationController: some View {
        Group {
            if horizontalSizeClass == .compact {
                TabBarView()
            } else {
                SidebarView()
            }
        }
    }
    
    var body: some View {
        if authorized {
            navigationController
                .environment(\.libraryOnline, online)
                .onContinueUserActivity(CSSearchableItemActionType, perform: SpotlightHelper.handleSpotlight)
                .onAppear {
                    #if ENABLE_ALL_FEATURES
                    INPreferences.requestSiriAuthorization { _ in }
                    #endif
                    
                    let path = NWPathMonitor().currentPath
                    if !path.isExpensive && !path.isConstrained {
                        SpotlightHelper.donate()
                        INMediaUserContext.donate()
                        
                        OfflineManager.shared.updateOfflineItems()
                        OfflineManager.shared.syncPlaysToJellyfinServer()
                    }
                    
                    JellyfinWebSocket.shared.connect()
                    AudioPlayer.current.allowRemoteControl = true
                }
                .onReceive(NotificationCenter.default.publisher(for: JellyfinClient.onlineStatusChanged), perform: { _ in
                    online = JellyfinClient.shared.isOnline
                })
        } else {
            LoginView() {
                authorized = true
            }
        }
    }
}

#Preview {
    ContentView()
}
