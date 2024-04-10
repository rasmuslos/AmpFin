//
//  NowPlayingBarSafeAreaModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import Foundation
import SwiftUI
import AFPlayback

// This thing is very funny, we will need this due to how Apple implemented NavigationSplitView.
// The NavigationSplitView is implemented with a wrapper around UIKit, so not a SwiftUI native component.
// A SwiftUI way to determine if we need the offset to make space for the sidebar is to monitor the binded
// value columnVisibility of the NavigationSplitView, but since this is a UIKit wrapped component, this value
// changes AFTER the view change has been commited, which means when the size of the view changes and triggers
// SwiftUI update, this value will not change until all animations are done. The onDisappear trigger also has
// similar problem, so we have to use our old friend GeometryReader to actually read the origin and pass the x
// value as our offset.
struct NowPlayingBarLeadingOffsetModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            GeometryReader { reader in
                Color.clear
                    .onChange(of: reader.frame(in: .global).origin) {
                        NotificationCenter.default.post(name: .init("b"), object: reader.frame(in: .global).origin.x)
                    }
            }
            .frame(height: 0)
            content
        }
    }
}

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
            // We need this because the modifier will only be applied to the root view of the NavigationStack, and
            // to add the NowPlayingBarModifier to each and every view in the stack maually is just horrible.
            // Also we can only embeded a NavigationSplitView inside a TabView but not the other way around.
            // This makes the the SwiftUI way of size negotialtion almost impossible.
            // Use GeometryReader is the only reliable way to determine the max width for our floating player.
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
