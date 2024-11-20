//
//  WelcomeView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 16.11.24.
//

import SwiftUI

extension LoginView {
    struct WelcomeView: View {
        @Binding var loginSheetPresented: Bool
        
        var body: some View {
            VStack(spacing: 4) {
                Spacer()
                
                Image("Logo")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.bottom, 40)
                
                Text("login.welcome")
                    .font(.headline)
                Text("login.text")
                    .font(.subheadline)
                
                Button {
                    loginSheetPresented.toggle()
                } label: {
                    Text("login.prompt")
                        .padding(.vertical, 12)
                        .padding(.horizontal, 44)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .font(.headline)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(.hoverMenuInteraction, RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .padding(20)
                
                Spacer()
            }
        }
    }
}

#Preview {
    LoginView.WelcomeView(loginSheetPresented: .constant(false))
}
