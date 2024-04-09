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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var isVisible: Bool {
        AudioPlayer.current.nowPlaying != nil
    }
    
    func body(content: Content) -> some View {
        if horizontalSizeClass == .compact {
            content
                .safeAreaPadding(.bottom, isVisible ? 75 : 0)
        } else {
            // this piece of shit is required because some apple engineer though it would be funny if a
            // navigation stack inside a split view detail section would do absolutely fucking nothing
            // https://forums.developer.apple.com/forums/thread/735672
            // https://stackoverflow.com/questions/76167468/strange-navigation-with-navigationstack-inside-navigationsplitview
            ZStack {
                GeometryReader { reader in
                    Color.clear
                        .onAppear {
                            NotificationCenter.default.post(name: .init("a"), object: reader.size.width)
                        }
                        .onChange(of: reader.size.width) {
                            NotificationCenter.default.post(name: .init("a"), object: reader.size.width)
                        }
                }
                .frame(height: 0)
                
                content
                    .safeAreaPadding(.bottom, isVisible ? 75 : 0)
            }
        }
    }
}
