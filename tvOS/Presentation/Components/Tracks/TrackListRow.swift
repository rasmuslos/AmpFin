//
//  TrackListRow.swift
//  tvOS
//
//  Created by Rasmus Krämer on 22.01.24.
//

import SwiftUI
import AFBase

struct TrackListRow: View {
    let track: Track
    
    var body: some View {
        HStack(spacing: 40) {
            ItemImage(cover: track.cover)
                .frame(width: 75)
            
            VStack(alignment: .leading) {
                Text(track.name)
                
                if let artistName = track.artistName {
                    Text(artistName)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
            
            Spacer()
            
            Text(track.runtime.timeLeft())
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
        }
        .font(.body)
    }
}
