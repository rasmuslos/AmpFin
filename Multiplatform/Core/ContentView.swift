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
                .onContinueUserActivity(CSQueryContinuationActionType) {
                    print($0)
                }
                .onContinueUserActivity(CSSearchableItemActionType) { activity in
                    guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
                        return
                    }
                    
                    SpotlightHelper.navigate(identifier: identifier)
                }
                .onContinueUserActivity("io.rfk.ampfin.album") { activity in
                    guard let identifier = activity.persistentIdentifier else {
                        return
                    }
                    
                    NotificationCenter.default.post(name: Navigation.navigateAlbumNotification, object: identifier)
                }
                .onContinueUserActivity("io.rfk.ampfin.artist") { activity in
                    guard let identifier = activity.persistentIdentifier else {
                        return
                    }
                    
                    NotificationCenter.default.post(name: Navigation.navigateArtistNotification, object: identifier)
                }
                .onContinueUserActivity("io.rfk.ampfin.playlist") { activity in
                    guard let identifier = activity.persistentIdentifier else {
                        return
                    }
                    
                    NotificationCenter.default.post(name: Navigation.navigatePlaylistNotification, object: identifier)
                }
                .onContinueUserActivity("io.rfk.ampfin.track") { activity in
                    guard let identifier = activity.persistentIdentifier else {
                        return
                    }
                    
                    SpotlightHelper.navigate(identifier: identifier)
                }
                .onAppear {
                    if AFKIT_ENABLE_ALL_FEATURES {
                        INPreferences.requestSiriAuthorization { _ in }
                    }
                    
                    let path = NWPathMonitor().currentPath
                    if !path.isExpensive && !path.isConstrained {
                        SpotlightHelper.updateIndex()
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
