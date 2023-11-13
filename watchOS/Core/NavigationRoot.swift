//
//  NavigationRoot.swift
//  watchOS
//
//  Created by Rasmus Krämer on 13.11.23.
//

import SwiftUI
import WatchKit
import MusicKit

struct NavigationRoot: View {
    @State var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            LibraryView()
                .navigationDestination(for: NowPlayingNavigationDestination.self) { _ in
                    NowPlayingView()
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: ConnectivityViewModel.nowPlayingActivityStarted)) { _ in
            navigationPath.append(NowPlayingNavigationDestination())
        }
        .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.playbackStarted), perform: { _ in
            navigationPath.append(NowPlayingNavigationDestination())
        })
    }
}

// MARK: Navigation destinations

extension NavigationRoot {
    struct NowPlayingNavigationDestination: Hashable {
    }
}

#Preview {
    NavigationRoot()
}
