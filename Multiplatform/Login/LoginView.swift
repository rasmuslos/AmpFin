//
//  LoginView.swift
//  Music
//
//  Created by Rasmus Krämer on 05.09.23.
//

import SwiftUI
import AmpFinKit

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    
    var body: some View {
        WelcomeView(loginSheetPresented: $viewModel.sheetPresented)
            .sheet(isPresented: $viewModel.sheetPresented, content: {
                NavigationStack {
                    switch viewModel.flowStep {
                    case .server, .credentials:
                        LoginFormView()
                    case .serverLoading, .credentialsLoading:
                        LoadingView()
                    }
                }
            })
            .transition(.opacity)
            .animation(.smooth, value: viewModel.flowStep)
            .environment(viewModel)
    }
}

#Preview {
    LoginView()
}
