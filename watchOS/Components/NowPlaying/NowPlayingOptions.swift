//
//  NowPlayingOptions.swift
//  watchOS
//
//  Created by Rasmus Krämer on 15.11.23.
//

import SwiftUI
import MusicKit

extension NowPlayingModifier {
    struct OptionsSheet: View {
        // this only works for local tracks right now, might make it work for remote ones sometime
        var body: some View {
            if true {
                let track = Track.fixture
            // if let track = AudioPlayer.shared.nowPlaying {
                VStack {
                    ItemImage(cover: track.cover)
                    
                    Text(track.name)
                        .font(.caption)
                    Text(track.artists.map { $0.name }.joined(separator: ", "))
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                    
                    Spacer()
                    
                    Button {
                        
                    } label: {
                        Label("favorite", systemImage: "heart")
                    }
                    .padding()
                }
                .ignoresSafeArea(edges: .bottom)
            } else {
                ErrorView()
            }
        }
    }
}

#Preview {
    NowPlayingModifier.OptionsSheet()
}
