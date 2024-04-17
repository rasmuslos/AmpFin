//
//  TrackListButtons.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct TrackListButtons: View {
    let startPlayback: (_ shuffle: Bool) -> ()
    
    var body: some View {
        HStack(spacing: 20) {
            Button {
                startPlayback(false)
            } label: {
                Label("queue.play", systemImage: "play.fill")
            }
            .buttonStyle(PlayButtonStyle())
            
            Button {
                startPlayback(true)
            } label: {
                Label("queue.shuffle", systemImage: "shuffle")
            }
            .buttonStyle(PlayButtonStyle())
        }
    }
}
