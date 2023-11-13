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
    @State var navigationPath = NavigationPath([LibraryNavigationDestination()])
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Home()
                .navigationDestination(for: NowPlayingNavigationDestination.self) { _ in
                    NowPlayingView()
                }
                .navigationDestination(for: LibraryNavigationDestination.self) { _ in
                    LibraryView()
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
    struct LibraryNavigationDestination: Hashable {
    }
}

#Preview {
    NavigationRoot()
}
