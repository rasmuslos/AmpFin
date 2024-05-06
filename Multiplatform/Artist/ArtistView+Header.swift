//
//  ArtistView+Header.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI
import Defaults
import AFBase
import AFPlayback

extension ArtistView {
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
                        .onAppear {
                            width = proxy.size.width
                        }
                        .onChange(of: proxy.frame(in: .global)) {
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
                        
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(artist.name)
                                        .bold()
                                        .font(.title)
                                        .foregroundStyle(.white)
                                    
                                    Spacer()
                                }
                                
                                if let overview = artist.overview {
                                    Button {
                                        overviewSheetPresented.toggle()
                                    } label: {
                                        Text(overview)
                                            .lineLimit(1)
                                            .foregroundStyle(Color.gray)
                                    }
                                    .buttonStyle(.plain)
                                    .sheet(isPresented: $overviewSheetPresented) {
                                        NavigationStack {
                                            ScrollView {
                                                Text(overview)
                                                    .padding(.outerSpacing)
                                            }
                                            .navigationTitle(artist.name)
                                            .presentationDragIndicator(.visible)
                                        }
                                    }
                                }
                            }
                            
                            Button {
                                if artistInstantMix {
                                    Task {
                                        try? await artist.startInstantMix()
                                    }
                                } else {
                                    Task {
                                        let tracks = try await dataProvider.getTracks(artistId: artist.id, sortOrder: .random, ascending: true)
                                        AudioPlayer.current.startPlayback(tracks: tracks, startIndex: 0, shuffle: false, playbackInfo: .init(container: artist))
                                    }
                                }
                            } label: {
                                Label("queue.mix", systemImage: "play.circle.fill")
                                    .labelStyle(.iconOnly)
                                    .modifier(ButtonHoverEffectModifier())
                            }
                            .font(.title)
                            .padding(.leading, .innerSpacing)
                            .popoverTip(ArtistPlaybackTip())
                        }
                        .padding(.outerSpacing)
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
