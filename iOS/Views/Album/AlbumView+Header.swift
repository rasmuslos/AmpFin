//
//  AlbumHeader.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import UIImageColors
import MusicKit

extension AlbumView {
    struct Header: View {
        let album: Album
        
        @Binding var navbarVisible: Bool
        @Binding var imageColors: ImageColors
        
        let startPlayback: (_ shuffle: Bool) -> ()
        
        var body: some View {
            ZStack(alignment: .top) {
                GeometryReader { reader in
                    let offset = reader.frame(in: .global).minY
                    
                    if offset > 0 {
                        Rectangle()
                            .foregroundStyle(imageColors.background)
                            .offset(y: -offset)
                            .frame(height: offset)
                    }
                    
                    Color.clear
                        .onChange(of: offset) {
                            navbarVisible = offset < -350
                        }
                }
                .frame(height: 0)
                
                VStack {
                    ItemImage(cover: album.cover)
                        .shadow(color: .black.opacity(0.25), radius: 20)
                        .frame(width: 275)
                    
                    Text(album.name)
                        .padding(.top)
                        .lineLimit(1)
                        .font(.headline)
                        .foregroundStyle(imageColors.isLight ? .black : .white)
                    
                    // fuck navigation links
                    if album.artists.count > 0 {
                        HStack {
                            Text(album.artistName)
                                .lineLimit(1)
                                .font(.callout)
                                .foregroundStyle(imageColors.detail)
                        }
                    }
                    
                    HStack {
                        if let releaseDate = album.releaseDate {
                            Text(String(releaseDate.get(.year)))
                        }
                        Text(album.genres.joined(separator: ", "))
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundStyle(imageColors.isLight ? Color.black.tertiary : Color.white.tertiary)
                    .padding(.bottom)
                    
                    HStack {
                        Group {
                            // why not buttons? because swiftui is a piece of shit
                            Label("queue.play", systemImage: "play.fill")
                                .onTapGesture {
                                    startPlayback(false)
                                }
                            Label("queue.shuffle", systemImage: "shuffle")
                                .onTapGesture {
                                    startPlayback(true)
                                }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(imageColors.secondary)
                        .background(imageColors.primary.opacity(0.25))
                        .bold()
                        .cornerRadius(7)
                    }
                }
                .padding(.top, 100)
                .padding(.bottom)
                .padding(.horizontal)
            }
            .background(imageColors.background)
            .listRowSeparator(.hidden)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
    }
}
