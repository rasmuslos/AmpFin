//
//  AlbumRow.swift
//  Music
//
//  Created by Rasmus Krämer on 17.10.23.
//

import SwiftUI
import AmpFinKit

struct AlbumRow: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let title: String
    let albums: [Album]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                    .padding(.leading, 20)
                    .padding(.bottom, 0)
                
                Image(systemName: "chevron.right.circle.fill")
                    .imageScale(.small)
                    .modifier(HoverEffectModifier())
            }
            .background {
                NavigationLink {
                    ScrollView {
                        AlbumGrid(albums: albums)
                            .padding(.horizontal, 20)
                    }
                    .navigationTitle(title)
                    .modifier(NowPlaying.SafeAreaModifier())
                } label: {
                    EmptyView()
                }
                .opacity(0)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(albums) { album in
                        NavigationLink(value: album) {
                            AlbumCover(album: album)
                        }
                        .buttonStyle(.plain)
                        .containerRelativeFrame(.horizontal) { length, _ in
                            let minimum = horizontalSizeClass == .compact ? 160.0 : 200.0
                            
                            let amount = CGFloat(Int(length / minimum))
                            let available = length - 12 * (amount - 1)
                            
                            return max(minimum, available / amount)
                        }
                        .padding(.trailing, 12)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    NavigationStack {
        List {
            AlbumRow(title: "Album fixtures", albums: [
                Album.fixture,
                Album.fixture,
                Album.fixture,
                Album.fixture,
                Album.fixture,
                Album.fixture,
            ])
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .listStyle(.plain)
    }
}
