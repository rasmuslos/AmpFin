//
//  InstantMixTip.swift
//  Music
//
//  Created by Rasmus Krämer on 12.11.23.
//

import SwiftUI
import TipKit

struct InstantMixTip: Tip {
    var title: Text {
        Text("tip.mix.title")
    }
    
    var message: Text? {
        Text("tip.mix.message")
    }
}
