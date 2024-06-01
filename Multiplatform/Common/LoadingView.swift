//
//  LoadingView.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI

internal struct LoadingView: View {
    var body: some View {
        VStack(spacing: 0) {
            ProgressView()
            
            Text("loading")
                .padding(20)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    LoadingView()
}
