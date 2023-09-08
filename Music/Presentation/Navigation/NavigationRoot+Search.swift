//
//  SearchTab.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

extension NavigationRoot {
    struct SearchTab: View {
        @State var history = [Track]()
        @State var queue = [Track]()
        
        var body: some View {
            List {
                Button {
                    AudioPlayer.shared.shuffle(!AudioPlayer.shared.shuffled)
                } label: {
                    Text("Shuffle")
                        .foregroundStyle(.red)
                }
                
                Text("Histroy")
                    .foregroundStyle(.red)
                
                ForEach(history) {
                    Text($0.name)
                }
                
                Text("Queue")
                    .foregroundStyle(.red)
                
                ForEach(queue) {
                    Text($0.name)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.QueueUpdated), perform: { _ in
                history = AudioPlayer.shared.history
                queue = AudioPlayer.shared.queue
            })
            .tabItem {
                Label("Serach", systemImage: "magnifyingglass")
            }
        }
    }
}
