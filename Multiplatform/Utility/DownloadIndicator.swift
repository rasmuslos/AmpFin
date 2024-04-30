//
//  DownloadIndicator.swift
//  Music
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import AFBase
import AFOffline

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
                Label("downloaded", systemImage: "arrow.down.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.caption)
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
