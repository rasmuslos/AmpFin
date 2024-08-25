//
//  ArtistView+Header.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI
import Defaults
import AmpFinKit
import AFPlayback

internal extension ArtistView {
    struct Header: View {
        @Default(.artistInstantMix) private var artistInstantMix
        @Environment(\.libraryDataProvider) private var dataProvider
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        let artist: Artist
        
        @State private var width: CGFloat = .zero
        @State private var parallax: CGFloat = .zero
        @State private var overscroll: CGFloat = .zero
        
        @State private var showNavigationBar = false
        @State private var overviewSheetPresented = false
        
        private var imageHeight: CGFloat {
            horizontalSizeClass == .compact ? width : 400
        }
        
        var body: some View {
            ZStack(alignment: .top) {
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.frame(in: .global), initial: true) {
                            let offset = proxy.frame(in: .global).minY
                            
                            if offset > 0 {
                                parallax = 0
                                overscroll = -offset
                            } else {
                                parallax = -offset
                                overscroll = 0
                            }
                            
                            width = proxy.size.width
                            showNavigationBar = offset < (horizontalSizeClass == .compact ? -300 : -350)
                        }
                }
                .frame(height: imageHeight)
                .background(alignment: .top) {
                    ItemImage(cover: artist.cover, cornerRadius: 0)
                        .scaledToFill()
                        .frame(width: width, height: imageHeight - overscroll - parallax / 2)
                        .clipped()
                        .offset(y: overscroll + parallax / 2)
                }
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    ZStack(alignment: .bottom) {
                        LinearGradient(colors: [.clear, .clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                        
                        HStack(alignment: .bottom, spacing: 0) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(artist.name)
                                    .bold()
                                    .font(.title)
                                    .foregroundStyle(.white)
                                
                                if let overview = artist.overview {
                                    Button {
                                        overviewSheetPresented.toggle()
                                    } label: {
                                        Text(overview)
                                            .lineLimit(1)
                                            .foregroundStyle(Color.gray)
                                    }
                                    .buttonStyle(.plain)
                                    .hoverEffectDisabled()
                                    .sheet(isPresented: $overviewSheetPresented) {
                                        NavigationStack {
                                            ScrollView {
                                                Text(overview)
                                                    .padding(20)
                                            }
                                            .navigationTitle(artist.name)
                                            .presentationDragIndicator(.visible)
                                        }
                                    }
                                }
                            }
                            
                            Spacer(minLength: 12)
                            
                            Button {
                                Task {
                                    if artistInstantMix {
                                        try? await artist.startInstantMix()
                                    } else {
                                        let tracks = try await dataProvider.tracks(artistId: artist.id, sortOrder: .random, ascending: true)
                                        AudioPlayer.current.startPlayback(tracks: tracks, startIndex: 0, shuffle: false, playbackInfo: .init(container: artist))
                                    }
                                }
                            } label: {
                                Label("queue.mix", systemImage: "play.circle.fill")
                                    .labelStyle(.iconOnly)
                            }
                            .buttonBorderShape(.circle)
                            .hoverEffect(.lift)
                            .font(.title)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(showNavigationBar ? .visible : .hidden, for: .navigationBar)
            .toolbar {
                if !showNavigationBar {
                    ToolbarItem(placement: .principal) {
                        Text(verbatim: "")
                    }
                }
            }
        }
    }
}
