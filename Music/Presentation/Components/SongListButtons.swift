//
//  SongListButtons.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct SongListButtons: View {
    var body: some View {
        HStack {
            Button {
                
            } label: {
                Label("Play", systemImage: "play.fill")
            }
            .buttonStyle(PlayButtonStyle())
            Button {
                
            } label: {
                Label("Shuffle", systemImage: "shuffle")
            }
            .buttonStyle(PlayButtonStyle())
        }
        .listRowInsets(.init(top: 0, leading: 0, bottom: 7, trailing: 0))
        .listRowSeparator(.hidden)
        .padding(.horizontal)
    }
}
