//
//  NavigationRoot+NowPlaying.swift
//  tvOS
//
//  Created by Rasmus Krämer on 19.01.24.
//

import Foundation
import SwiftUI

extension NavigationRoot {
    struct NowPlayingTabView: View {
        var body: some View {
            NowPlayingView()
                .tabItem {
                    Text("title.nowPlaying")
                }
        }
    }
}
