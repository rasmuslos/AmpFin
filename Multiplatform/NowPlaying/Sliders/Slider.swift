//
//  Slider.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI

internal extension NowPlaying {
    struct Slider: View {
        @Binding var percentage: Double
        @Binding var dragging: Bool
        
        @State private var counter = 0
        @State private var blocked = false
        
        @State private var lastLocation: CGPoint? = nil
        
        var body: some View {
            GeometryReader { geometry in
                let width = geometry.size.width * min(1, max(0, CGFloat(self.percentage)))
                
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundStyle(.white.opacity(0.4))
                        .saturation(1.6)
                    
                    Rectangle()
                        .frame(width: width)
                        .foregroundStyle(.white)
                        .opacity(dragging ? 0.8 : 0.4)
                        .animation(.smooth, value: width)
                        .animation(.smooth, value: dragging)
                }
                .clipShape(.rect(cornerRadius: 8))
                .gesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .global)
                    .onChanged { value in
                        if blocked {
                            return
                        }
                        
                        counter += 1
                        
                        if counter < 7 {
                            return
                        }
                        counter = 0
                        
                        dragging = true
                        blocked = true
                        
                        guard let lastLocation else {
                            lastLocation = value.location
                            blocked = false
                            
                            return
                        }
                        
                        let velocity = value.velocity.width
                        let acceleration = velocity > 300 ? 1.5 : 1.2
                        
                        let delta = value.location.x - lastLocation.x
                        let offset = (delta / geometry.size.width) * acceleration
                        
                        self.lastLocation = value.location
                        
                        percentage = min(1, max(0, percentage + offset))
                        blocked = false
                    }
                    .onEnded { _ in
                        dragging = false
                        lastLocation = nil
                    }
                )
            }
            .frame(height: dragging ? 12 : 8)
            .shadow(radius: dragging ? 12 : 0)
            .padding(20)
            .contentShape(.hoverMenuInteraction, .rect)
            .padding(-20)
            .animation(.spring, value: dragging)
        }
    }
}

#Preview {
    @Previewable @State var dragging = false
    @Previewable @State var percentage = 0.5
    
    NowPlaying.Slider(percentage: $percentage, dragging: $dragging)
        .padding(.horizontal)
}
