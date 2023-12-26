//
//  ArtistView+Header.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI
import AFBaseKit

extension ArtistView {
    struct Header: View {
        let artist: Artist
        
        @State var width: CGFloat = .zero
        @State var offset: CGFloat = .zero
        
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
                                self.offset = offset
                            } else {
                                self.offset = 0
                            }
                            
                            width = proxy.size.width
                            showNavigationBar = offset < -300
                        }
                }
                .frame(height: width)
                .background {
                    ItemImage(cover: artist.cover, cornerRadius: 0)
                        .scaledToFill()
                        .frame(width: width, height: width + offset)
                        .offset(y: offset / -2)
                }
                
                VStack {
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
                                Task {
                                    try? await artist.startInstantMix()
                                }
                            } label: {
                                Image(systemName: "play.circle.fill")
                            }
                            .font(.title)
                            .padding(.leading)
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
