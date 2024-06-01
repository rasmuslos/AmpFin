//
//  HistoryTip.swift
//  Music
//
//  Created by Rasmus Krämer on 12.11.23.
//

import SwiftUI
import TipKit

internal struct HistoryTip: Tip {
    var title: Text {
        Text("tip.history.title")
    }
    
    var message: Text? {
        Text("tip.history.message")
    }
    
    var options: [TipOption] = [
        MaxDisplayCount(5)
    ]
}
