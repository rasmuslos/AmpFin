//
//  Transition+Opacity.swift
//  iOS
//
//  Created by Rasmus Krämer on 22.03.24.
//

import SwiftUI

struct OpacityTransitionModifier: ViewModifier {
    let active: Bool
    let min: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(active ? min : 1)
    }
}

extension AnyTransition {
    static func opacity(min: Double) -> Self {
        .modifier(
            active: OpacityTransitionModifier(active: true, min: min),
            identity: OpacityTransitionModifier(active: false, min: min))
    }
}
