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
        HStack {
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
        .listRowInsets(.init(top: 0, leading: 0, bottom: 7, trailing: 0))
        .listRowSeparator(.hidden)
        .padding(.horizontal)
    }
}
