//
//  NowPlayingSheet+Title.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI

// MARK: Cover

extension NowPlayingSheet {
    struct Cover: View {
        let track: Track
        let namespace: Namespace.ID
        @Binding var playing: Bool
        
        var body: some View {
            Spacer()
            
            ItemImage(cover: track.cover)
                .scaleEffect(playing ? 1 : 0.8)
                .animation(.spring(duration: 0.25, bounce: 0.5), value: playing)
                .matchedGeometryEffect(id: "image", in: namespace, properties: .frame, anchor: .topLeading, isSource: true)
            
            Spacer()
            
            HStack {
                VStack(alignment: .leading) {
                    Text(track.name)
                        .bold()
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                        .matchedGeometryEffect(id: "title", in: namespace, properties: .frame, anchor: .topLeading, isSource: true)
                    Text(track.artists.map { $0.name }.joined(separator: ", "))
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                        .matchedGeometryEffect(id: "artist", in: namespace, properties: .frame, anchor: .topLeading, isSource: true)
                }
                .font(.system(size: 18))
                
                Spacer()
                
                MenuButton(track: track)
                    .matchedGeometryEffect(id: "menu", in: namespace, properties: .frame, anchor: .topLeading, isSource: true)
            }
            .padding(.vertical)
        }
    }
}

// MARK: Small Title

extension NowPlayingSheet {
    struct SmallTitle: View {
        let track: Track
        let namespace: Namespace.ID
        @Binding var currentTab: Tab
        
        var body: some View {
            HStack() {
                ItemImage(cover: track.cover)
                    .frame(width: 60, height: 60)
                    .matchedGeometryEffect(id: "image", in: namespace, properties: .frame, anchor: .topLeading, isSource: true)
                    .onTapGesture {
                        withAnimation {
                            currentTab = .cover
                        }
                    }
                
                VStack(alignment: .leading) {
                    Text(track.name)
                        .lineLimit(1)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .matchedGeometryEffect(id: "title", in: namespace, properties: .frame, anchor: .topLeading, isSource: true)
                    Text(track.artists.map { $0.name }.joined(separator: ", "))
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .matchedGeometryEffect(id: "artist", in: namespace, properties: .frame, anchor: .topLeading, isSource: true)
                }
                
                Spacer()
                
                MenuButton(track: track)
                    .matchedGeometryEffect(id: "menu", in: namespace, properties: .frame, anchor: .topLeading, isSource: true)
            }
            .padding(.top, 40)
        }
    }
}

// MARK: Menu Button

extension NowPlayingSheet {
    struct MenuButton: View {
        let track: Track
        
        var body: some View {
            Button {
                Task.detached {
                    try? await track.setFavorite(favorite: !track.favorite)
                }
            } label: {
                Image(systemName: track.favorite ? "heart.fill" : "heart")
                    .font(.system(size: 24))
                    .symbolRenderingMode(.palette)
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(.white, .gray.opacity(0.25))
            }
        }
    }
}
