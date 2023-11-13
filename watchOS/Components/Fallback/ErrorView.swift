//
//  ErrorView.swift
//  watchOS
//
//  Created by Rasmus Krämer on 13.11.23.
//

import SwiftUI

struct ErrorView: View {
    var body: some View {
        ContentUnavailableView("error.unavailable.title", systemImage: "xmark.circle", description: Text("error.unavailable.text"))
    }
}

#Preview {
    ErrorView()
}
