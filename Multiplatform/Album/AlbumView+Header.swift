//
//  AlbumHeader.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import UIImageColors
import AFBase

extension AlbumView {
    struct Header: View {
        let album: Album
        let imageColors: ImageColors
        
        @Binding var toolbarBackgroundVisible: Bool
        
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
                            withAnimation {
                                toolbarBackgroundVisible = offset < -350
                            }
                        }
                }
                .frame(height: 0)
                
                ViewThatFits(in: .horizontal) {
                    RegularPresentation(album: album, imageColors: imageColors, toolbarBackgroundVisible: toolbarBackgroundVisible, startPlayback: startPlayback)
                    CompactPresentation(album: album, imageColors: imageColors, toolbarBackgroundVisible: toolbarBackgroundVisible, startPlayback: startPlayback)
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

// MARK: Common components

extension AlbumView.Header {
    struct AlbumTitle: View {
        @Environment(\.libraryDataProvider) private var dataProvider
        
        let album: Album
        let largeFont: Bool
        let imageColors: ImageColors
        
        var body: some View {
            Text(album.name)
                .padding(.top)
                .lineLimit(1)
                .font(largeFont ? .title : .headline)
                .foregroundStyle(imageColors.isLight ? .black : .white)
            
            if album.artists.count > 0 {
                HStack {
                    Text(album.artistName)
                        .lineLimit(1)
                        .font(largeFont ? .title2 : .callout)
                        .foregroundStyle(imageColors.detail)
                }
                .onTapGesture {
                    if let artist = album.artists.first, dataProvider.supportsArtistLookup {
                        NotificationCenter.default.post(name: Navigation.navigateArtistNotification, object: artist.id)
                    }
                }
            }
            
            HStack {
                if let releaseDate = album.releaseDate {
                    Text(releaseDate, format: Date.FormatStyle().year())
                }
                
                Text(album.genres.joined(separator: String(localized: "genres.separator")))
                    .lineLimit(1)
            }
            .font(.caption)
            .foregroundStyle(imageColors.primary.opacity(0.75))
        }
    }
}

extension AlbumView.Header {
    struct PlayButtons: View {
        let imageColors: ImageColors
        let startPlayback: (_ shuffle: Bool) -> ()
        
        var body: some View {
            HStack {
                Group {
                    Label("queue.play", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            startPlayback(false)
                        }
                    Label("queue.shuffle", systemImage: "shuffle")
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            startPlayback(true)
                        }
                }
                .padding(.vertical, 12)
                .padding(.horizontal)
                .foregroundColor(imageColors.secondary)
                .background(imageColors.primary.opacity(0.25))
                .bold()
                .cornerRadius(7)
            }
        }
    }
}

// MARK: Adaptive presentations

extension AlbumView.Header {
    struct CompactPresentation: View {
        let album: Album
        let imageColors: ImageColors
        let toolbarBackgroundVisible: Bool
        let startPlayback: (_ shuffle: Bool) -> ()
        
        var body: some View {
            VStack {
                ItemImage(cover: album.cover)
                    .shadow(color: .black.opacity(0.25), radius: 20)
                    .frame(width: 275)
                
                AlbumTitle(album: album, largeFont: false, imageColors: imageColors)
                PlayButtons(imageColors: imageColors, startPlayback: startPlayback)
                    .padding(.top)
            }
        }
    }
}

extension AlbumView.Header {
    struct RegularPresentation: View {
        let album: Album
        let imageColors: ImageColors
        let toolbarBackgroundVisible: Bool
        let startPlayback: (_ shuffle: Bool) -> ()
        
        var body: some View {
            HStack {
                ItemImage(cover: album.cover)
                    .shadow(color: .black.opacity(0.25), radius: 20)
                    .frame(width: 275)
                    .padding(.trailing)
                
                VStack(alignment: .leading) {
                    Spacer()
                    AlbumTitle(album: album, largeFont: true, imageColors: imageColors)
                    Spacer()
                    PlayButtons(imageColors: imageColors, startPlayback: startPlayback)
                }
            }
            .padding(.bottom)
        }
    }
}
