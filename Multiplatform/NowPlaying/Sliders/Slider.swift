//
//  Slider.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI

internal extension NowPlaying {
    struct Slider: View {
        @Environment(\.colorScheme) private var colorScheme
        
        @Binding var percentage: Double
        @Binding var dragging: Bool
        
        @State private var counter = 0
        @State private var blocked = false
        
        @State private var captured: Double? = nil
        @State private var displayed: Double? = nil
        
        var body: some View {
            ZStack {
                GeometryReader { geometry in
                    let width = geometry.size.width * min(1, max(0, CGFloat(displayed ?? percentage)))
                    
                    ZStack(alignment: .leading) {
                        if colorScheme == .dark {
                            Rectangle()
                                .fill(.background.tertiary)
                                .saturation(1.6)
                        } else {
                            Rectangle()
                                .fill(.background.secondary)
                                .saturation(1.6)
                        }
                        
                        Rectangle()
                            .frame(width: width)
                            .foregroundStyle(.primary)
                            .animation(.smooth, value: width)
                    }
                    .clipShape(.rect(cornerRadius: 8))
                    .highPriorityGesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .global)
                        .onChanged {
                            dragging = true
                            
                            if captured == nil {
                                captured = percentage
                            }
                            
                            let width = geometry.size.width
                            let offset = min(width, max(-width, $0.translation.width))
                            
                            let moved: Double = .init(offset / width)
                            let velocity = abs($0.velocity.width)
                            let acceleration: Double
                            
                            if velocity < 500 {
                                acceleration = 0.8
                            } else if velocity < 1000 {
                                acceleration = 1
                            } else {
                                acceleration = 1.2
                            }
                            
                            let modifier = moved * acceleration
                            displayed = captured! + modifier
                        }
                        .onEnded { _ in
                            dragging = false
                            
                            if let displayed {
                                percentage = displayed
                            }
                            
                            displayed = nil
                            captured = nil
                        }
                    )
                }
                .frame(height: dragging ? 10 : 6)
                .shadow(color: .black.opacity(0.2), radius: dragging ? 10 : 0)
                .padding(20)
                .contentShape(.hoverMenuInteraction, .rect)
                .padding(-20)
                .animation(.spring, value: dragging)
            }
            .frame(height: 10)
        }
    }
}

#Preview {
    @Previewable @State var dragging = false
    @Previewable @State var percentage = 0.5
    
    NowPlaying.Slider(percentage: $percentage, dragging: $dragging)
        .padding(.horizontal)
}
