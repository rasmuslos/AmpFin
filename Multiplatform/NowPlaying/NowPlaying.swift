//
//  NowPlaying.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 03.05.24.
//

import Foundation
import SwiftUI
import AmpFinKit
import AFPlayback

internal struct NowPlaying {
    private init() {}
    
    enum Tab {
        case cover
        case lyrics
        case queue
    }
}

internal extension NowPlaying {
    static let widthChangeNotification = NSNotification.Name("io.rfk.ampfin.sidebar.width.changed")
    static let offsetChangeNotification = NSNotification.Name("io.rfk.ampfin.sidebar.offset.changed")
}

internal struct NowPlayingOverlayToggled: TransactionKey {
    static var defaultValue = false
}

internal extension Transaction {
    var nowPlayingOverlayToggled: Bool {
        get { self[NowPlayingOverlayToggled.self] }
        set { self[NowPlayingOverlayToggled.self] = newValue }
    }
}
