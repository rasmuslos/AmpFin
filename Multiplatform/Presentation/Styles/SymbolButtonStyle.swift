//
//  SymbolButtonStyle.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import SwiftUI

struct SymbolButtonStyle: ButtonStyle {
    var active: Bool
    var heavy = false
    
    private var color: Color {
        heavy ? .black.opacity(0.2) : .white.opacity(0.25)
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .aspectRatio(1, contentMode: .fit)
            .padding(7)
            .background(active ? color : .clear)
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
    .buttonStyle(SymbolButtonStyle(active: false))
}


#Preview {
    Button {
        
    } label: {
        Image(systemName: "shuffle")
    }
    .buttonStyle(SymbolButtonStyle(active: true))
}
