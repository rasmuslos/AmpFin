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
    
    private var navigationController: some View {
        Group {
            #if os(visionOS)
            XRTabs()
            #else
            if horizontalSizeClass == .compact {
                Tabs()
            } else {
                Sidebar()
            }
            #endif
        }
    }
    
    var body: some View {
        if JellyfinClient.shared.authorized {
            navigationController
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
                    
                    Navigation.navigate(albumId: identifier)
                }
                .onContinueUserActivity("io.rfk.ampfin.artist") { activity in
                    guard let identifier = activity.persistentIdentifier else {
                        return
                    }
                    
                    Navigation.navigate(artistId: identifier)
                }
                .onContinueUserActivity("io.rfk.ampfin.playlist") { activity in
                    guard let identifier = activity.persistentIdentifier else {
                        return
                    }
                    
                    Navigation.navigate(playlistId: identifier)
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
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
}
