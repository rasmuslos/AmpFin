//
//  AlbumView+Toolbar.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AmpFinKit

extension AlbumView {
    struct ToolbarModifier: ViewModifier {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(\.isPresented) private var isPresented
        @Environment(\.dismiss) private var dismiss
        
        @Environment(\.libraryDataProvider) private var dataProvider
        @Environment(AlbumViewModel.self) private var viewModel
        
        private var isCompact: Bool {
            horizontalSizeClass == .compact
        }
        private var alignment: HorizontalAlignment {
            #if os(visionOS)
            .leading
            #else
            .center
            #endif
        }
        
        private var toolbarBackgroundVisibility: Visibility {
            if !isCompact {
                return .automatic
            }
            
            return viewModel.toolbarBackgroundVisible ? .visible : .hidden
        }
        private var isCustomBackButtonVisible: Bool {
            return isCompact && isPresented && !viewModel.toolbarBackgroundVisible
        }
        
        func body(content: Content) -> some View {
            content
                .navigationTitle(viewModel.album.name)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(!viewModel.toolbarBackgroundVisible && isCompact)
                .toolbarBackground(toolbarBackgroundVisibility, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        if isCustomBackButtonVisible {
                            Button {
                                dismiss()
                            } label: {
                                Label("back", systemImage: "chevron.left")
                                    .modifier(FullscreenToolbarModifier())
                            }
                            .transition(.move(edge: .leading))
                        }
                    }
                    
                    ToolbarItem(placement: .principal) {
                        if viewModel.toolbarBackgroundVisible {
                            VStack(alignment: alignment) {
                                Text(viewModel.album.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                if let releaseDate = viewModel.album.releaseDate {
                                    Text(releaseDate, style: .date)
                                        .font(.caption2)
                                        .lineLimit(1)
                                }
                            }
                        } else {
                            Text(verbatim: "")
                        }
                    }
                    
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Group {
                            switch viewModel.downloadStatus {
                                case .none:
                                    Button {
                                        viewModel.download()
                                    } label: {
                                        Label("download", systemImage: "arrow.down")
                                            .labelStyle(.iconOnly)
                                    }
                                case .downloaded:
                                    Button {
                                        viewModel.evict()
                                    } label: {
                                        Label("download.remove", systemImage: "xmark")
                                            .labelStyle(.iconOnly)
                                    }
                                default:
                                    ProgressView()
                            }
                        }
                        .modifier(FullscreenToolbarModifier())
                    
                        ToolbarMenu()
                    }
                }
        }
    }
}

private struct ToolbarMenu: View {
    @Environment(\.libraryDataProvider) private var dataProvider
    @Environment(AlbumViewModel.self) private var viewModel
    
    var body: some View {
        Menu {
            Button {
                viewModel.album.favorite.toggle()
            } label: {
                Label("favorite", systemImage: viewModel.album.favorite ? "star.fill" : "star")
            }
            
            Button {
                viewModel.instantMix()
            } label: {
                Label("queue.mix", systemImage: "compass.drawing")
            }
            .disabled(!JellyfinClient.shared.online)
            
            Divider()
            
            QueueButtons {
                viewModel.queue(now: $0)
            }
            
            Button {
                
            } label: {
                Label("timer", systemImage: "clock")
            }
            
            ForEach(viewModel.album.artists) { artist in
                Divider()
                
                NavigationLink(value: .artistLoadDestination(artistId: artist.id)) {
                    Label("artist.view", systemImage: "music.mic")
                    Text(artist.name)
                }
                .disabled(!dataProvider.supportsArtistLookup)
            }
            
            Divider()
            
            if viewModel.downloadStatus != .none {
                Button(role: .destructive) {
                    viewModel.evict()
                } label: {
                    Label(viewModel.downloadStatus == .working ? "download.remove.force" : "download.remove", systemImage: "trash")
                        .foregroundStyle(.red)
                }
            }
        } label: {
            // Label("more", systemImage: "ellipsis")
            Image(systemName: "ellipsis")
                .labelStyle(.iconOnly)
                .modifier(FullscreenToolbarModifier())
        }
    }
}

private struct FullscreenToolbarModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    @Environment(AlbumViewModel.self) private var viewModel
    
    func body(content: Content) -> some View {
        if horizontalSizeClass == .compact && !viewModel.toolbarBackgroundVisible {content
            .symbolVariant(.circle.fill)
            .symbolRenderingMode(.palette)
            .foregroundStyle(
                colorScheme == .dark ? .black : .white,
                (colorScheme == .dark ? Color.white : .black).opacity(0.4)
            )
        } else {
            content
                .symbolVariant(.circle)
        }
    }
}
