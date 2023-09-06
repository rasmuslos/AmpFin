//
//  NowPlayingBar.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI

struct NowPlayingBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                RoundedRectangle(cornerRadius: 15)
                // Set tabbar background
                    .toolbarBackground(.hidden, for: .tabBar)
                    .background {
                        Rectangle()
                            .frame(width: UIScreen.main.bounds.width + 100, height: 300)
                            .offset(y: 130)
                            .blur(radius: 25)
                            .foregroundStyle(.ultraThickMaterial)
                    }
                    .foregroundStyle(.ultraThinMaterial)
                // add content
                    .overlay {
                        HStack {
                            RoundedRectangle(cornerRadius: 7)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(.green)
                                .padding(.leading, 5)
                            
                            Text("Hello, World!")
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Group {
                                Button {
                                    
                                } label: {
                                    Image(systemName: "play.fill")
                                }
                                
                                Button {
                                    
                                } label: {
                                    Image(systemName: "forward.fill")
                                }
                                .padding(.horizontal, 10)
                            }
                            .imageScale(.large)
                        }
                        .padding(.horizontal, 6)
                    }
                    .foregroundStyle(.primary)
                // style bar
                    .padding(.horizontal, 15)
                    .padding(.bottom, 10)
                    .frame(height: 65)
                    .shadow(color: .black.opacity(0.25), radius: 20)
            }
    }
}
