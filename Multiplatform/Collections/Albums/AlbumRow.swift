//
//  AlbumRow.swift
//  Music
//
//  Created by Rasmus Krämer on 17.10.23.
//

import SwiftUI
import AFBase

struct AlbumRow: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let title: String
    let albums: [Album]
    
    @State private var width: CGFloat = .zero
    
    private let gap: CGFloat = .connectedSpacing
    private let padding: CGFloat = .outerSpacing
    
    // For some reason HGrid do not work in ScrollViews, so we have to calculate this ourselves
    private var size: CGFloat {
        let minimum = horizontalSizeClass == .compact ? 160.0 : 200.0
        
        let usable = width - padding * 2
        let amount = CGFloat(Int(usable / minimum))
        let available = usable - gap * (amount - 1)
        
        return max(minimum, available / amount)
    }
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        width = proxy.size.width
                    }
                    .onChange(of: proxy.size.width) {
                        width = proxy.size.width
                    }
            }
            .frame(height: 0)
            
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.headline)
                        .padding(.leading, .outerSpacing)
                        .padding(.bottom, 0)
                        .padding(.top, .connectedSpacing)
                    
                    Image(systemName: "chevron.right.circle.fill")
                        .imageScale(.small)
                        .modifier(ButtonHoverEffectModifier())
                }
                .background {
                    NavigationLink {
                        ScrollView {
                            AlbumGrid(albums: albums)
                                .padding(.horizontal, .outerSpacing)
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
                            NavigationLink(destination: AlbumView(album: album)) {
                                AlbumCover(album: album)
                                    .frame(width: size)
                                    .padding(.leading, gap)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.leading, gap)
                    .padding(.trailing, padding)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollClipDisabled()
            }
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
