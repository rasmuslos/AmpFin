//
//  PlayButtonStyle.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct PlayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(.accentColor)
            .background(.thickMaterial)
            .bold()
            .cornerRadius(7)
    }
}

#Preview {
    Button {
        
    } label: {
        Label("Command :)", systemImage: "Command :)")
    }
    .buttonStyle(PlayButtonStyle())
}
