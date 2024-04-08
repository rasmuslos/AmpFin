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
        @Environment(\.libraryDataProvider) var dataProvider
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Default(.artistInstantMix) private var artistInstantMix
        
        let artist: Artist
        
        @State var width: CGFloat = .zero
        @State var parallax: CGFloat = .zero
        @State var overscroll: CGFloat = .zero
        
        @State var showNavigationBar = false
        @State var overviewSheetPresented = false
        
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
                .frame(height: horizontalSizeClass == .compact ? width : 400)
                .background {
                    ItemImage(cover: artist.cover, cornerRadius: 0)
                        .scaledToFill()
                        .frame(width: width, height: width - overscroll)
                        .offset(y: (overscroll + parallax) / 2)
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
                                                    .padding()
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
                                        let tracks = try await dataProvider.getTracks(artistId: artist.id)
                                        AudioPlayer.current.startPlayback(tracks: tracks, startIndex: 0, shuffle: false, playbackInfo: .init())
                                    }
                                }
                            } label: {
                                Image(systemName: "play.circle.fill")
                            }
                            .font(.title)
                            .padding(.leading)
                            .popoverTip(ArtistPlaybackTip())
                        }
                        .padding()
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
