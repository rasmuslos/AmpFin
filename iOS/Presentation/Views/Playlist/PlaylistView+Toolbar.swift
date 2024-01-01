//
//  PlaylistView+Toolbar.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import SwiftUI

extension PlaylistView {
    struct ToolbarModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            
                        } label: {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.25))
                    }
                }
        }
    }
}
