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
    
    // For some reason HGrid do not work in ScrollViews, so we have to calculate this ourselves
    private var size: CGFloat {
        let minimum = horizontalSizeClass == .compact ? 160.0 : 200.0
        
        let padding: CGFloat = 20
        let gap: CGFloat = 10
        
        let amount = CGFloat(Int(width / minimum))
        let available = width - padding * 2 - gap * (amount - 1)
        
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
                        .padding(.leading)
                        .padding(.bottom, 0)
                        .padding(.top, 10)
                    
                    Image(systemName: "chevron.right.circle.fill")
                        .imageScale(.small)
                }
                .background {
                    NavigationLink {
                        ScrollView {
                            AlbumGrid(albums: albums)
                        }
                        .navigationTitle(title)
                        .padding(.horizontal)
                        .modifier(NowPlayingBarSafeAreaModifier())
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
                                    .padding(.leading, 10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.leading, 10)
                    .padding(.trailing, 20)
                }
                .scrollTargetBehavior(.viewAligned)
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
