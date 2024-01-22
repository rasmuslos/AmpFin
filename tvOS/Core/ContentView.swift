//
//  ContentView.swift
//  tvOS
//
//  Created by Rasmus Krämer on 14.01.24.
//

import SwiftUI
import AFBase

struct ContentView: View {
    @State var isAuthorized = JellyfinClient.shared.isAuthorized
    
    var body: some View {
        if isAuthorized {
            NavigationRoot()
        } else {
            LoginView() {
                print("a")
                isAuthorized = true
            }
        }
    }
}

#Preview {
    ContentView()
}
