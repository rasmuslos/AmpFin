//
//  ButtonHoverEffectModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.05.24.
//

import SwiftUI

internal struct HoverEffectModifier: ViewModifier {
    var padding: CGFloat = 8
    var cornerRadius: CGFloat = 12
    
    var hoverEffect: HoverEffect = .highlight
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .contentShape(.hoverMenuInteraction, .rect(cornerRadius: cornerRadius))
            .hoverEffect(hoverEffect)
            .padding(-padding)
    }
}
