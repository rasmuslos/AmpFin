//
//  DownloadIndicator.swift
//  Music
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import AmpFinKit

internal struct DownloadIndicator: View {
    let item: Item
    
    @State private var offlineTracker: ItemOfflineTracker?
    
    var body: some View {
        Group {
            if offlineTracker?.status == .downloaded {
                Label("downloaded", systemImage: "arrow.down.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if offlineTracker?.status == .working || true {
                ProgressView()
                    .scaleEffect(0.5)
            }
        }
        .padding(.horizontal, 4)
        .foregroundStyle(.secondary)
        
        if offlineTracker == nil {
            Color.clear
                .frame(width: 0, height: 0)
                .onAppear {
                    offlineTracker = item.offlineTracker
                }
        }
    }
}
