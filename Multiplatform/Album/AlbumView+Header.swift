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
        @Environment(AlbumViewModel.self) private var viewModel
        
        var body: some View {
            ZStack(alignment: .top) {
                GeometryReader { proxy in
                    let minY = proxy.frame(in: .global).minY
                    
                    Color.clear
                        .onChange(of: minY, initial: true) {
                            withAnimation(.spring) {
                                viewModel.toolbarBackgroundVisible = minY < (horizontalSizeClass == .regular ? -120 : -350)
                            }
                        }
                }
                .frame(height: 0)
                
                VStack(spacing: 0) {
                    Group {
                        ViewThatFits {
                            RegularPresentation()
                            CompactPresentation()
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Divider()
                        .padding(.top, 16)
                        .padding(.leading, 20)
                }
                .padding(.top, 120)
            }
            .listRowSeparator(.hidden)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
    }
}

private struct AlbumTitle: View {
    @Environment(\.libraryDataProvider) private var dataProvider
    @Environment(AlbumViewModel.self) private var viewModel
    
    let largeFont: Bool
    let alignment: HorizontalAlignment
    
    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(viewModel.album.name)
                .multilineTextAlignment(alignment == .leading ? .leading : .center)
                .font(largeFont ? .title : .headline)
            
            if let artistName = viewModel.album.artistName {
                Text(artistName)
                    .lineLimit(1)
                    .font(largeFont ? .title2 : .callout)
                    .foregroundStyle(.secondary)
                    .onTapGesture {
                        if let artist = viewModel.album.artists.first, dataProvider.supportsArtistLookup {
                            Navigation.navigate(artistId: artist.id)
                        }
                    }
            }
            
            if viewModel.album.releaseDate != nil || !viewModel.album.genres.isEmpty {
                HStack(spacing: 0) {
                    if let releaseDate = viewModel.album.releaseDate {
                        Text(releaseDate, format: Date.FormatStyle().year())
                        
                        if !viewModel.album.genres.isEmpty {
                            Text(verbatim: " • ")
                        }
                    }
                    
                    Text(viewModel.album.genres.joined(separator: String(", ")))
                        .lineLimit(1)
                }
                .font(.caption2)
                .bold()
                .foregroundStyle(.tertiary)
            }
        }
    }
}

private struct PlayButtons: View {
    @Environment(AlbumViewModel.self) private var viewModel
    
    var body: some View {
        HStack(spacing: 12) {
            PlayButton(icon: "play.fill", label: "queue.play") {
                viewModel.play(shuffled: false)
            }
            
            PlayButton(icon: "shuffle", label: "queue.shuffle") {
                viewModel.play(shuffled: true)
            }
        }
    }
}

private struct PlayButton: View {
    @Environment(AlbumViewModel.self) private var viewModel
    
    let icon: String
    let label: LocalizedStringKey
    
    let callback: () -> Void
    
    var body: some View {
        ZStack {
            // This horrible abomination ensures that both buttons have the same height
            Label(String("TEXT"), systemImage: "shuffle")
                .hidden()
            
            Label(label, systemImage: icon)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .bold()
        .foregroundColor(.accentColor)
        .background(.secondary.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(.hoverMenuInteraction, RoundedRectangle(cornerRadius: 12))
        .hoverEffect(.lift)
        .onTapGesture {
            callback()
        }
    }
}

private struct CompactPresentation: View {
    @Environment(AlbumViewModel.self) private var viewModel
    
    var body: some View {
        VStack(spacing: 16) {
            ItemImage(cover: viewModel.album.cover)
                .shadow(color: .black.opacity(0.25), radius: 20)
                .frame(width: 280)
            
            AlbumTitle(largeFont: false, alignment: .center)
            
            PlayButtons()
        }
    }
}

private struct RegularPresentation: View {
    @Environment(AlbumViewModel.self) private var viewModel
    
    var body: some View {
        HStack(spacing: 0) {
            ItemImage(cover: viewModel.album.cover)
                .shadow(color: .black.opacity(0.25), radius: 20)
                .frame(width: 280)
                .padding(.trailing, 20)
            
            Color.clear
                .frame(minWidth: 240)
                .overlay {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                        AlbumTitle(largeFont: true, alignment: .leading)
                        Spacer()
                        PlayButtons()
                    }
                }
        }
        .padding(.bottom, 8)
    }
}

