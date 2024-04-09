//
//  NowPlayingBarSafeAreaModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import Foundation
import SwiftUI
import AFPlayback

struct NowPlayingBarSafeAreaModifier: ViewModifier {
    private var isVisible: Bool {
        AudioPlayer.current.nowPlaying != nil
    }
    
    func body(content: Content) -> some View {
        content
            .safeAreaPadding(.bottom, isVisible ? 75 : 0)
    }
}
