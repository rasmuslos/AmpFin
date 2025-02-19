//
//  PlaylistView+Toolbar.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import SwiftUI
import AmpFinKit

internal extension PlaylistView {
    struct ToolbarModifier: ViewModifier {
        @Environment(PlaylistViewModel.self) private var viewModel
        
        func body(content: Content) -> some View {
            content
                .toolbar {
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
                        .symbolVariant(.circle)
                    
                        if viewModel.editMode == .active {
                            Button {
                                withAnimation {
                                    viewModel.editMode = .inactive
                                }
                            } label: {
                                Label("done", systemImage: "checkmark")
                                    .labelStyle(.iconOnly)
                                    .symbolVariant(.circle)
                            }
                        } else {
                            Menu {
                                Button {
                                    viewModel.playlist.favorite.toggle()
                                } label: {
                                    Label("favorite", systemImage: viewModel.playlist.favorite ? "star.fill" : "star")
                                }
                                
                                Divider()
                                
                                Button {
                                    viewModel.play(shuffled: false)
                                } label: {
                                    Label("queue.play", systemImage: "play.fill")
                                }
                                Button {
                                    viewModel.play(shuffled: true)
                                } label: {
                                    Label("queue.shuffle", systemImage: "shuffle")
                                }
                                
                                Divider()
                                
                                QueueButtons {
                                    viewModel.queue(now: $0)
                                }
                                
                                SleepTimerMenu(
                                    // TODO: This feels wrong, I don't fully understand reactivity in Swift
                                    hasActiveTimer: Binding<Bool>(
                                        get: { viewModel.hasSleepTimer },
                                        set: {
                                            if !$0 {
                                                viewModel.cancelSleepTimer()
                                            }
                                        }
                                    ),
                                    set: viewModel.startSleepTimer,
                                    unset: viewModel.cancelSleepTimer
                                )
                                
                                
                                Divider()
                                
                                Button {
                                    withAnimation {
                                        viewModel.editMode = .active
                                    }
                                } label: {
                                    Label("playlist.edit", systemImage: "pencil")
                                }
                                .disabled(!JellyfinClient.shared.online)
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    viewModel.deleteAlertPresented.toggle()
                                } label: {
                                    Label("playlist.delete", systemImage: "xmark")
                                }
                                .disabled(!JellyfinClient.shared.online)
                                
                                if viewModel.downloadStatus != .none {
                                    Button(role: .destructive) {
                                        viewModel.evict()
                                    } label: {
                                        Label(viewModel.downloadStatus == .working ? "download.remove.force" : "download.remove", systemImage: "trash")
                                            .foregroundStyle(.red)
                                    }
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .symbolVariant(.circle)
                            }
                        }
                    }
                }
        }
    }
}
