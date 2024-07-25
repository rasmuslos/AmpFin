//
//  QueueButtons.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.07.24.
//

import SwiftUI
import AFPlayback

internal struct QueueButtons: View {
    let action: (Bool) -> Void
    
    @State private var feedback = false
    
    var body: some View {
        QueueNextButton {
            action(true)
        }
        QueueLaterButton {
            action(false)
        }
    }
}

internal struct QueueNextButton: View {
    @State private var feedback = false
    
    let action: () -> Void
    
    var body: some View {
        Button {
            feedback.toggle()
            action()
        } label: {
            Label("queue.next", systemImage: "text.line.first.and.arrowtriangle.forward")
        }
        .sensoryFeedback(.success, trigger: feedback)
    }
}
internal struct QueueLaterButton: View {
    @State private var feedback = false
    
    var forceDisplay = false
    let action: () -> Void
    
    var body: some View {
        if AudioPlayer.current.allowQueueLater {
            Button {
                feedback.toggle()
                action()
            } label: {
                Label("queue.last", systemImage: "text.line.last.and.arrowtriangle.forward")
                
                if let lastName = AudioPlayer.current.queue.last?.name {
                    Text("queue.last.name \(lastName)")
                }
            }
        }
    }
}

#Preview {
    QueueButtons() { _ in }
}
