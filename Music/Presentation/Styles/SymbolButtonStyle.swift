//
//  SymbolButtonStyle.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI

struct SymbolButtonStyle: ButtonStyle {
    @Binding var active: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .aspectRatio(1, contentMode: .fit)
            .padding(7)
            .background(active ? .white.opacity(0.25) : .clear)
            .foregroundStyle(active ? .primary : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .animation(.easeInOut, value: active)
    }
}

#Preview {
    Button {
        
    } label: {
        Image(systemName: "shuffle")
    }
    .buttonStyle(SymbolButtonStyle(active: .constant(false)))
}


#Preview {
    Button {
        
    } label: {
        Image(systemName: "shuffle")
    }
    .buttonStyle(SymbolButtonStyle(active: .constant(true)))
}
