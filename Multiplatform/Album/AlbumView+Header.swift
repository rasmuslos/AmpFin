//
//  AlbumHeader.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import UIImageColors
import AmpFinKit

internal extension AlbumView {
    struct Header: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
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
                            .fill(imageColors.background.gradient.opacity(0.8))
                            .offset(y: -offset)
                            .frame(height: offset)
                    }
                    
                    Color.clear
                        .onChange(of: offset) {
                            withAnimation(.spring) {
                                toolbarBackgroundVisible = offset < (horizontalSizeClass == .regular ? -120 : -350)
                            }
                        }
                }
                .frame(height: 0)
                
                Group {
                    ViewThatFits {
                        RegularPresentation(album: album, imageColors: imageColors, toolbarBackgroundVisible: toolbarBackgroundVisible, startPlayback: startPlayback)
                        CompactPresentation(album: album, imageColors: imageColors, toolbarBackgroundVisible: toolbarBackgroundVisible, startPlayback: startPlayback)
                    }
                }
                .padding(.top, 120)
                .padding(.bottom, 12)
                .padding(.horizontal, 20)
            }
            .background(imageColors.background)
            .listRowSeparator(.hidden)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
    }
}


private struct AlbumTitle: View {
    @Environment(\.libraryDataProvider) private var dataProvider
    
    let album: Album
    let largeFont: Bool
    let imageColors: ImageColors
    let alignment: HorizontalAlignment
    
    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(album.name)
                .multilineTextAlignment(alignment == .leading ? .leading : .center)
                .font(largeFont ? .title : .headline)
                .foregroundStyle(imageColors.isLight ? .black : .white)
            
            if let artistName = album.artistName {
                Text(artistName)
                    .lineLimit(1)
                    .font(largeFont ? .title2 : .callout)
                    .foregroundStyle(imageColors.detail)
                    .onTapGesture {
                        if let artist = album.artists.first, dataProvider.supportsArtistLookup {
                            Navigation.navigate(artistId: artist.id)
                        }
                    }
            }
            
            if album.releaseDate != nil || !album.genres.isEmpty {
                HStack(spacing: 0) {
                    if let releaseDate = album.releaseDate {
                        Text(releaseDate, format: Date.FormatStyle().year())
                        
                        if !album.genres.isEmpty {
                            Text(verbatim: " • ")
                        }
                    }
                    
                    Text(album.genres.joined(separator: String(", ")))
                        .lineLimit(1)
                }
                .font(.caption.smallCaps())
                .foregroundStyle(imageColors.primary.opacity(0.75))
            }
        }
    }
}


private struct PlayButtons: View {
    let imageColors: ImageColors
    let startPlayback: (_ shuffle: Bool) -> ()
    
    var body: some View {
        HStack(spacing: 12) {
            PlayButton(icon: "play.fill", label: "queue.play", imageColors: imageColors) {
                startPlayback(false)
            }
            
            PlayButton(icon: "shuffle", label: "queue.shuffle", imageColors: imageColors) {
                startPlayback(true)
            }
        }
    }
}

private struct PlayButton: View {
    let icon: String
    let label: LocalizedStringKey
    let imageColors: ImageColors
    
    let callback: () -> Void
    
    var body: some View {
        ZStack {
            // This horrible abomination ensures that both buttons have the same height
            Label(String("TEXT"), systemImage: "shuffle")
                .opacity(0)
            
            Label(label, systemImage: icon)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .bold()
        .foregroundColor(imageColors.secondary)
        .background(imageColors.primary.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(.hoverMenuInteraction, RoundedRectangle(cornerRadius: 12))
        .hoverEffect(.lift)
        .onTapGesture {
            callback()
        }
    }
}

private struct CompactPresentation: View {
    let album: Album
    let imageColors: ImageColors
    let toolbarBackgroundVisible: Bool
    let startPlayback: (_ shuffle: Bool) -> ()
    
    var body: some View {
        VStack(spacing: 16) {
            ItemImage(cover: album.cover)
                .shadow(color: .black.opacity(0.25), radius: 20)
                .frame(width: 280)
            
            AlbumTitle(album: album, largeFont: false, imageColors: imageColors, alignment: .center)
            
            PlayButtons(imageColors: imageColors, startPlayback: startPlayback)
        }
    }
}

private struct RegularPresentation: View {
    let album: Album
    let imageColors: ImageColors
    let toolbarBackgroundVisible: Bool
    let startPlayback: (_ shuffle: Bool) -> ()
    
    var body: some View {
        HStack(spacing: 0) {
            ItemImage(cover: album.cover)
                .shadow(color: .black.opacity(0.25), radius: 20)
                .frame(width: 280)
                .padding(.trailing, 20)
            
            Color.clear
                .frame(minWidth: 240)
                .overlay {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                        AlbumTitle(album: album, largeFont: true, imageColors: imageColors, alignment: .leading)
                        Spacer()
                        PlayButtons(imageColors: imageColors, startPlayback: startPlayback)
                    }
                }
        }
        .padding(.bottom, 8)
    }
}

