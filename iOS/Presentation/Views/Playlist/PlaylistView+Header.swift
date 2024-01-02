//
//  PlaylistView+Header.swift
//  iOS
//
//  Created by Rasmus Krämer on 01.01.24.
//

import SwiftUI
import AFBaseKit

extension PlaylistView {
    struct Header: View {
        let playlist: Playlist
        let startPlayback: (_ shuffle: Bool) -> ()
        
        @State var height: CGFloat = .zero
        @State var offset: CGFloat = .zero
        
        var body: some View {
            ZStack {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            height = max(height, proxy.size.height)
                        }
                        .onChange(of: proxy.size.height) {
                            height = max(height, proxy.size.height)
                        }
                        .onChange(of: proxy.frame(in: .global)) {
                            height = max(height, proxy.size.height)
                            offset = proxy.frame(in: .global).minY
                            
                            if offset < 0 {
                                offset = 0
                            }
                        }
                }
                
                VStack {
                    Spacer(minLength: 400)
                    
                    HStack {
                        Text("playlist.trackCount \(playlist.trackCount)")
                        + Text(verbatim: " • ")
                        + Text(formatDuration())
                    }
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 10)
                    
                    TrackListButtons(startPlayback: startPlayback)
                }
                .padding(.bottom)
                .background {
                    Background(playlist: playlist)
                        .offset(y: -offset)
                        .frame(height: height + offset * 2)
                }
            }
        }
    }
}

extension PlaylistView.Header {
    func formatDuration() -> String {
        let seconds = Int(playlist.duration)
        let hours = seconds / 3600
        
        if hours > 0 {
            return String(localized: "hours \(hours)")
        } else {
            return String(localized: "minutes \((seconds % 3600) / 60)")
        }
    }
}
