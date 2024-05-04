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
        
        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundStyle(.white.tertiary)
                    Rectangle()
                        .foregroundStyle(dragging ? Color.white : Color.white.opacity(0.8))
                        .frame(width: geometry.size.width * min(1, max(0, CGFloat(self.percentage / 100))))
                }
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .modifier(ButtonHoverEffectModifier())
                .highPriorityGesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        percentage = min(max(0, Double(value.location.x / geometry.size.width * 100)), 100)
                        dragging = true
                    }
                    .onEnded { _ in
                        dragging = false
                    }
                )
            }
            .frame(height: dragging ? 10 : 7)
            .animation(.easeInOut, value: dragging)
        }
    }
}

#Preview {
    VStack {
        NowPlaying.Slider(percentage: .constant(50), dragging: .constant(false))
            .padding(.horizontal)
    }
}
