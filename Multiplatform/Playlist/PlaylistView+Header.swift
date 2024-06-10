//
//  PlaylistView+Header.swift
//  iOS
//
//  Created by Rasmus Krämer on 01.01.24.
//

import SwiftUI
import AmpFinKit

internal extension PlaylistView {
    struct Header: View {
        let playlist: Playlist
        
        @Binding var toolbarVisible: Bool
        
        let startPlayback: (_ shuffle: Bool) -> ()
        
        @State private var height: CGFloat = .zero
        @State private var offset: CGFloat = .zero
        
        var body: some View {
            ZStack {
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.size.height, initial: true) {
                            height = max(height, proxy.size.height)
                        }
                        .onChange(of: proxy.frame(in: .global)) {
                            height = max(height, proxy.size.height)
                            offset = proxy.frame(in: .global).minY
                            
                            if offset < 0 {
                                offset = 0
                            }
                        }
                        .onChange(of: proxy.frame(in: .global).minY) {
                            toolbarVisible = proxy.frame(in: .global).minY < 0
                        }
                }
                
                VStack(spacing: 0) {
                    Spacer(minLength: 400)
                    
                    HStack {
                        Text("playlist.trackCount \(playlist.trackCount)")
                        + Text(verbatim: " • ")
                        + Text(playlist.duration.duration)
                    }
                    .font(.subheadline.smallCaps())
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)
                    
                    TrackListButtons(background: .ultraThinMaterial, startPlayback: startPlayback)
                }
                .padding(.bottom, 12)
                .padding(.horizontal, 20)
                .background {
                    Background(playlist: playlist)
                        .offset(y: -offset)
                        .frame(height: height + offset * 2)
                }
                
                VStack {
                    Rectangle()
                        .foregroundStyle(.linearGradient(colors: [.gray.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                        .frame(height: 220)
                        .offset(y: -offset)
                    
                    Spacer()
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
    }
}
