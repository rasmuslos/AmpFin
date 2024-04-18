//
//  TrackListButtons.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct TrackListButtons: View {
    var background: Material = .ultraThickMaterial
    
    let startPlayback: (_ shuffle: Bool) -> ()
    
    var body: some View {
        HStack(spacing: 20) {
            Group {
                Button {
                    startPlayback(false)
                } label: {
                    Label("queue.play", systemImage: "play.fill")
                }
                
                Button {
                    startPlayback(true)
                } label: {
                    Label("queue.shuffle", systemImage: "shuffle")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(background)
            .foregroundColor(.accentColor)
            .bold()
            .cornerRadius(7)
        }
    }
}

#Preview {
    TrackListButtons {
        print($0)
    }
}
