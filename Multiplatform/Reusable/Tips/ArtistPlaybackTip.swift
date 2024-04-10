//
//  ArtistPlaybackTip.swift
//  iOS
//
//  Created by Rasmus Krämer on 23.03.24.
//

import SwiftUI
import TipKit

struct ArtistPlaybackTip: Tip {
    var title: Text {
        Text("tip.artistPlayback.title")
    }
    
    var message: Text? {
        Text("tip.artistPlayback.message")
    }
    
    var options: [TipOption] = [
        MaxDisplayCount(5)
    ]
}
