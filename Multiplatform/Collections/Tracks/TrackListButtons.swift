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
        HStack(spacing: 12) {
            TrackListButton(icon: "play.fill", label: "queue.play", background: background) {
                startPlayback(false)
            }
            
            TrackListButton(icon: "shuffle", label: "queue.shuffle", background: background) {
                startPlayback(true)
            }
        }
    }
}

private struct TrackListButton : View {
    let icon: String
    let label: LocalizedStringKey
    
    let background: Material
    let callback: () -> Void
    
    var body: some View {
        ZStack {
            // This horrible abomination ensures that both buttons have the same height
            Label(String("TEXT"), systemImage: "shuffle")
                .opacity(0)
            
            Label(label, systemImage: icon)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .bold()
        .foregroundColor(.accentColor)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(.hoverMenuInteraction, RoundedRectangle(cornerRadius: 12))
        .hoverEffect(.lift)
        .onTapGesture {
            callback()
        }
    }
}

#Preview {
    TrackListButtons { _ in }
}
