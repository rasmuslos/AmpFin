//
//  TrackGrid.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.05.24.
//

import SwiftUI
import AFBase
import AFPlayback

struct TrackGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let tracks: [Track]
    let container: Item?
    
    var amount = 2
    
    @State private var width: CGFloat = .zero
    
    private let gap: CGFloat = 10
    private let padding: CGFloat = 20
    
    private var size: CGFloat {
        let minimum = horizontalSizeClass == .compact ? 300 : 450.0
        
        let usable = width - padding * 2
        let amount = CGFloat(Int(usable / minimum))
        let available = usable - gap * (amount - 1)
        
        return max(minimum, available / amount)
    }
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.size.width, initial: true) {
                        width = proxy.size.width
                    }
            }
            .frame(height: 0)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: [GridItem(.flexible())].repeated(count: amount), spacing: 0) {
                    ForEach(tracks) { track in
                        TrackListRow(track: track, disableMenu: true) {
                            if let index = tracks.firstIndex(where: { $0.id == track.id }) {
                                AudioPlayer.current.startPlayback(tracks: tracks, startIndex: index, shuffle: false, playbackInfo: .init(container: container))
                            }
                        }
                        .padding(.leading, gap)
                        .frame(width: size)
                    }
                }
                .scrollTargetLayout()
                .padding(.leading, gap)
                .padding(.trailing, padding)
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

#Preview {
    TrackGrid(tracks: [
        .fixture,
        .fixture,
        .fixture,
        .fixture,
        .fixture,
        .fixture,
        .fixture,
    ], container: nil)
}
