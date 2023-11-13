//
//  NowPlayingModifier.swift
//  watchOS
//
//  Created by Rasmus Krämer on 13.11.23.
//

import SwiftUI

struct NowPlayingModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: NavigationRoot.NowPlayingNavigationDestination()) {
                        Image(systemName: "waveform")
                    }
                }
            }
    }
}
