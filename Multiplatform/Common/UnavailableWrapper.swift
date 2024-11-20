//
//  UnavailableWrapper.swift
//  AmpFin
//
//  Created by Rasmus Krämer on 20.11.24.
//

import SwiftUI

internal struct UnavailableWrapper<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        ScrollView {
            ZStack {
                Spacer()
                    .containerRelativeFrame([.horizontal, .vertical])
                
                content
            }
        }
    }
}
