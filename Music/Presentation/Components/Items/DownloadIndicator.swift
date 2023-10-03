//
//  DownloadIndicator.swift
//  Music
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI

struct DownloadIndicator: View {
    let item: Item
    
    var body: some View {
        Group {
            if item.offline == .downloaded {
                Image(systemName: "arrow.down.circle.fill")
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
            } else if item.offline == .working {
                ProgressView()
                    .scaleEffect(0.75)
            }
        }
        .padding(.horizontal, 4)
        .foregroundStyle(.secondary)
    }
}
