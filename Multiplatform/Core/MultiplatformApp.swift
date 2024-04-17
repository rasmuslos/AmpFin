//
//  MusicApp.swift
//  Music
//
//  Created by Rasmus Krämer on 05.09.23.
//

import SwiftUI
import SwiftData
import TipKit
import AFBase
import AFOffline
import CoreSpotlight

@main
struct MultiplatformApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        #if !ENABLE_ALL_FEATURES
        AFKIT_ENABLE_ALL_FEATURES = false
        #endif
        
        try? Tips.configure([
            .displayFrequency(.daily)
        ])
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
                #if false
                .overlay {
                    // add some layout guidelines to make sure that the padding is consistently 20 units.
                    // i am convinced that the implicit behavior of `.padding()` is meant to troll people, there is no other explanation for why it would be so terrible
                    HStack(spacing: 0) {
                        Rectangle()
                            .frame(width: 1)
                            .padding(.leading, 20)
                            .foregroundStyle(.red)
                        
                        Spacer()
                        
                        Rectangle()
                            .frame(width: 1)
                            .padding(.trailing, 20)
                            .foregroundStyle(.red)
                    }
                }
                #endif
        }
        .modelContainer(PersistenceManager.shared.modelContainer)
    }
}
