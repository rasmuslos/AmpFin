//
//  MusicApp.swift
//  Music
//
//  Created by Rasmus Krämer on 05.09.23.
//

import SwiftUI
import Nuke
import Defaults
import AmpFinKit

@main
struct MultiplatformApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        #if !ENABLE_ALL_FEATURES
        AFKIT_ENABLE_ALL_FEATURES = false
        #endif
        
        ImagePipeline.shared = ImagePipeline(configuration: .withDataCache)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                #if targetEnvironment(macCatalyst)
                .onAppear {
                    UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }
                        .forEach { $0.titlebar?.titleVisibility = .hidden }
                }
                #endif
        }
        .modelContainer(PersistenceManager.shared.modelContainer)
    }
}
