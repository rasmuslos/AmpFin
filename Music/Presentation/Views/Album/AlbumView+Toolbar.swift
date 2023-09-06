//
//  AlbumView+Toolbar.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI

extension AlbumView {
    struct ToolbarModifier: ViewModifier {
        @Environment(\.presentationMode) var presentationMode
        
        let album: AlbumItem
        
        @Binding var navbarVisible: Bool
        @Binding var imageColors: ImageColors
        
        func body(content: Content) -> some View {
            content
                .toolbarBackground(navbarVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(!navbarVisible)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if navbarVisible {
                            VStack {
                                Text(album.name)
                                    .font(.headline)
                                if let releaseDate = album.releaseDate {
                                    Text(String(releaseDate.get(.year)))
                                        .font(.caption2)
                                }
                            }
                        } else {
                            Text("")
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        if !navbarVisible && presentationMode.wrappedValue.isPresented {
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .modifier(FullscreenToolbarModifier(navbarVisible: $navbarVisible, imageColors: $imageColors))
                            }
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            
                        } label: {
                            // and for some other reason this was blue when i used a label
                            Image(systemName: "arrow.down")
                                .modifier(FullscreenToolbarModifier(navbarVisible: $navbarVisible, imageColors: $imageColors))
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Label("Option 1", systemImage: "command")
                            Label("Option 1", systemImage: "command")
                        } label: {
                            // for some reason it did show the label...
                            Image(systemName: "ellipsis")
                                .modifier(FullscreenToolbarModifier(navbarVisible: $navbarVisible, imageColors: $imageColors))
                        }
                    }
                }
        }
    }
    
    struct FullscreenToolbarModifier: ViewModifier {
        @Binding var navbarVisible: Bool
        @Binding var imageColors: ImageColors
        
        func body(content: Content) -> some View {
            content
                // .font(.system(size: 16))
                .imageScale(.large)
                .symbolVariant(.circle.fill)
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    navbarVisible ? Color.accentColor : imageColors.isLight ? .black : .white,
                    navbarVisible ? .black.opacity(0.1) : .black.opacity(0.25))
                .animation(.easeInOut, value: navbarVisible)
        }
    }
}
