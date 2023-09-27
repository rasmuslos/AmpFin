//
//  AccountToolbarButton.swift
//  Music
//
//  Created by Rasmus Krämer on 27.09.23.
//

import SwiftUI

struct AccountToolbarButtonModifier: ViewModifier {
    @State var accountSheetPresented = false
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        accountSheetPresented.toggle()
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .sheet(isPresented: $accountSheetPresented) {
                AccountSheet()
            }
    }
}
