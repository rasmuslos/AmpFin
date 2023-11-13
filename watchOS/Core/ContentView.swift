//
//  ContentView.swift
//  watchOS Watch App
//
//  Created by Rasmus Krämer on 13.11.23.
//

import SwiftUI
import UIKit
import WatchKit
import Intents

struct ContentView: View {
    @WKApplicationDelegateAdaptor var delegateAdaptor: DelegateAdaptor
    @WKExtensionDelegateAdaptor var extensionAdaptor: ExtensionAdaptor
    
    var body: some View {
        NowPlayingView()
            .onAppear {
                print("Hello")
            }
    }
}

class DelegateAdaptor: NSObject, WKApplicationDelegate {
    func handleRemoteNowPlayingActivity() {
        print("now playing 1")
    }
    
    func handle(_ userActivity: NSUserActivity) {
        print(userActivity, "ua1")
    }
    
    func handleUserActivity(_ userInfo: [AnyHashable : Any]?) {
        print(userInfo, "ua1.2")
    }
}
    
class ExtensionAdaptor: NSObject, WKExtensionDelegate {
    func handleRemoteNowPlayingActivity() {
        print("now playing 2")
    }
    
    func handle(_ userActivity: NSUserActivity) {
        print(userActivity, "ua2")
    }
    
    func handleUserActivity(_ userInfo: [AnyHashable : Any]?) {
        print(userInfo, "ua2.2")
    }
}

#Preview {
    ContentView()
}
