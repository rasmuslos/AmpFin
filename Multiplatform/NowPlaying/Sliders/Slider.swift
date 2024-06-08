//
//  Slider.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI

extension NowPlaying {
    struct Slider: View {
        @Binding var percentage: Double
        @Binding var dragging: Bool
        
        @State private var lastLocation: CGPoint? = nil
        
        var body: some View {
            GeometryReader { geometry in
                let width = geometry.size.width * min(1, max(0, CGFloat(self.percentage)))
                
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundStyle(.ultraThinMaterial)
                    
                    Rectangle()
                        .frame(width: width)
                        .animation(.spring, value: width)
                        .foregroundStyle(dragging ? .ultraThickMaterial : .thickMaterial)
                }
                .clipShape(.rect(cornerRadius: 8))
                .highPriorityGesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragging = true
                        
                        guard let lastLocation else {
                            lastLocation = value.location
                            return
                        }
                        
                        let delta = value.location.x - lastLocation.x
                        let offset = (delta / geometry.size.width)
                        
                        self.lastLocation = value.location
                        percentage = min(1, max(0, percentage + offset))
                    }
                    .onEnded { _ in
                        dragging = false
                        lastLocation = nil
                    }
                )
            }
            .frame(height: dragging ? 12 : 8)
            .padding(20)
            .contentShape(.hoverMenuInteraction, .rect)
            .padding(-20)
            .animation(.spring, value: dragging)
        }
    }
}

#Preview {
    NowPlaying.Slider(percentage: .constant(50), dragging: .constant(false))
        .padding(.horizontal)
}
