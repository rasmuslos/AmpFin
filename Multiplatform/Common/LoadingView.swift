//
//  LoadingView.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ProgressView()
        Text("loading")
            .padding()
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    LoadingView()
}
