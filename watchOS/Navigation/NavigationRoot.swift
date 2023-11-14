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
    @State var navigationPath = NavigationPath([ListenNowNavigationDestination()])
    @State var dataProvider: LibraryDataProvider = OfflineLibraryDataProvider()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Home()
                .navigationDestination(for: NowPlayingNavigationDestination.self) { _ in
                    NowPlayingView()
                }
                .navigationDestination(for: ListenNowNavigationDestination.self) { _ in
                    ListenNowView()
                }
                .navigationDestination(for: LibraryNavigationDestination.self) { _ in
                    LibraryView()
                        .navigationTitle("title.library")
                        .onAppear {
                            dataProvider = OnlineLibraryDataProvider()
                        }
                }
                .navigationDestination(for: DownloadsNavigationDestination.self) { _ in
                    LibraryView()
                        .navigationTitle("title.downloads")
                        .onAppear {
                            dataProvider = OfflineLibraryDataProvider()
                        }
                }
                .navigationDestination(for: SearchNavigationDestination.self) { _ in
                    Text(":)")
                }
        }
        .environment(\.libraryDataProvider, dataProvider)
        .onReceive(NotificationCenter.default.publisher(for: ConnectivityViewModel.nowPlayingActivityStarted)) { _ in
            navigationPath.append(NowPlayingNavigationDestination())
        }
        .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.playbackStarted), perform: { _ in
            navigationPath.append(NowPlayingNavigationDestination())
        })
    }
}

#Preview {
    NavigationRoot()
}
