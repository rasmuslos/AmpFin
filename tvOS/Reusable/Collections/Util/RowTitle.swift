//
//  RowTitle.swift
//  tvOS
//
//  Created by Rasmus Krämer on 19.01.24.
//

import SwiftUI

struct RowTitle: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.gray.opacity(0.9))
            
            Spacer()
        }
        .padding(.leading, 45)
    }
}

#Preview {
    RowTitle(title: "Hello, World!")
}
