//
//  DownloadIndicator.swift
//  Music
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import AFBaseKit
import AFOfflineKit

struct DownloadIndicator: View {
    let item: Item
    let offlineTracker: ItemOfflineTracker
    
    init(item: Item) {
        self.item = item
        offlineTracker = item.offlineTracker
    }
    
    var body: some View {
        Group {
            if offlineTracker.status == .downloaded {
                Image(systemName: "arrow.down.circle.fill")
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
            } else if offlineTracker.status == .working {
                ProgressView()
                    .scaleEffect(0.75)
            }
        }
        .padding(.horizontal, 4)
        .foregroundStyle(.secondary)
    }
}
