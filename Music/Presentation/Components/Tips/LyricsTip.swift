//
//  LyricsTip.swift
//  Music
//
//  Created by Rasmus Krämer on 12.11.23.
//

import SwiftUI
import TipKit

struct LyricsTip: Tip {
    var title: Text {
        Text("tip.lyrics.title")
    }
    
    var message: Text? {
        Text("tip.lyrics.message")
    }
    
    var options: [TipOption] = [
        IgnoresDisplayFrequency(true)
    ]
}
