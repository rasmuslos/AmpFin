//
//  RemoteTip.swift
//  iOS
//
//  Created by Rasmus Krämer on 23.03.24.
//

import SwiftUI
import TipKit

internal struct RemoteTip: Tip {
    var title: Text {
        Text("tip.remote.title")
    }
    
    var message: Text? {
        Text("tip.remote.message")
    }
    
    var options: [TipOption] = [
        MaxDisplayCount(5)
    ]
}

