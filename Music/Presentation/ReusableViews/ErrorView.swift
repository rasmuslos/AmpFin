//
//  ErrorView.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI

struct ErrorView: View {
    var body: some View {
        Text("Unable to load")
            .foregroundStyle(.red)
    }
}

#Preview {
    ErrorView()
}
