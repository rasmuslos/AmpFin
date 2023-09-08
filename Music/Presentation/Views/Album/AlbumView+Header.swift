//
//  AlbumHeader.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import UIImageColors

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
                    
                    Rectangle()
                        .foregroundStyle(imageColors.background)
                        .offset(y: -offset)
                        .frame(height: offset)
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
                    
                    // if let first = album.artists.first {
                    // TODO: add link here, fuck navigation links
                        Text(album.artists.map { $0.name }.joined(separator: ", "))
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(imageColors.detail)
                    // }
                    
                    HStack {
                        if let releaseDate = album.releaseDate {
                            Text(String(releaseDate.get(.year)))
                        }
                        Text(album.genres.joined(separator: ", "))
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.bottom)
                    
                    HStack {
                        Group {
                            Button {
                                startPlayback(false)
                            } label: {
                                Label("Play", systemImage: "play.fill")
                            }
                            Button {
                                startPlayback(true)
                            } label: {
                                Label("Shuffle", systemImage: "shuffle")
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
