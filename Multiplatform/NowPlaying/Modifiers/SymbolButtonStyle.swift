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
            .modifier(ForegroundStyleModifier(active: active, heavy: heavy))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .animation(.easeInOut, value: active)
    }
}

private struct ForegroundStyleModifier: ViewModifier {
    let active: Bool
    let heavy: Bool
    
    func body(content: Content) -> some View {
        if heavy {
            content
                .foregroundStyle(active ? .primary : .secondary)
        } else {
            content
                .foregroundStyle(active ? .thickMaterial : .thinMaterial)
        }
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


#Preview {
    Button {
        
    } label: {
        Image(systemName: "shuffle")
    }
    .buttonStyle(SymbolButtonStyle(active: false, heavy: true))
}


#Preview {
    Button {
        
    } label: {
        Image(systemName: "shuffle")
    }
    .buttonStyle(SymbolButtonStyle(active: true, heavy: false))
}
