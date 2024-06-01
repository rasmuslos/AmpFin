//
//  DownloadTip.swift
//  Music
//
//  Created by Rasmus Krämer on 12.11.23.
//

import SwiftUI
import TipKit

internal struct DownloadTip: Tip {
    var title: Text {
        Text("tip.download.title")
    }
    
    var message: Text? {
        Text("tip.download.message")
    }
    
    var options: [TipOption] = [
        MaxDisplayCount(5)
    ]
}
