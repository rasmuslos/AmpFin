//
//  LoadingView.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI

internal struct LoadingView: View {
    var body: some View {
        UnavailableWrapper {
            VStack(spacing: 4) {
                ProgressView()
                Text("loading")
                    .foregroundStyle(.gray)
            }
        }
    }
}

#Preview {
    LoadingView()
}
