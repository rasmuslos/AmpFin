//
//  SleepTimerMenu.swift
//  AmpFin
//
//  Created by Aaron Leopold on 2/19/25.
//

import SwiftUI
import AFPlayback

internal struct SleepTimerMenu: View {
    private let options: [Int] = [5, 10, 30, 60, 120]
    
    @Binding var hasActiveTimer: Bool
    let set: (_: Int) -> Void
    let unset: () -> Void
    
    var body: some View {
        Menu {
            ForEach(0 ..< self.options.count) { index in
                Button {
                    self.set(self.options[index])
                } label: {
                    Text("\(self.options[index]) minutes")
                }
            }
            
            Button(role: .destructive) {
                self.unset()
            } label: {
                Text("Cancel timer")
            }
            .disabled(!self.hasActiveTimer)
        } label: {
            Label("Sleep timer", systemImage: "clock")
        }
    }
}
