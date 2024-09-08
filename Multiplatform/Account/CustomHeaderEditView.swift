//
//  HeaderEditView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 03.09.24.
//

import SwiftUI
import AmpFinKit

struct CustomHeaderEditView: View {
    @State private var current = JellyfinClient.shared.customHTTPHeaders
    
    var callback: (() -> Void)? = nil
    
    var body: some View {
        List {
            ForEach(Array(current.enumerated()), id: \.offset) { (index, pair) in
                Section {
                    Group {
                        TextField("login.customHTTPHeaders.key", text: .init(get: { pair.key }, set: { current[index].key = $0 }))
                        TextField("login.customHTTPHeaders.value", text: .init(get: { pair.value }, set: { current[index].value = $0 }))
                    }
                    .fontDesign(.monospaced)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    
                    Button(role: .destructive) {
                        current.remove(at: index)
                    } label: {
                        Text("login.customHTTPHeaders.remove")
                    }
                }
            }
        }
        .navigationTitle("login.customHTTPHeaders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    current.append(.init(key: "", value: ""))
                } label: {
                    Label("login.customHTTPHeaders.add", systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
                
                Button {
                    JellyfinClient.shared.customHTTPHeaders = current
                    callback?()
                } label: {
                    Label("login.customHTTPHeaders.save", systemImage: "checkmark")
                        .labelStyle(.titleOnly)
                }
            }
        }
        .onAppear {
            if current.isEmpty {
                current.append(.init(key: "", value: ""))
            }
        }
    }
}

#Preview {
    NavigationStack {
        CustomHeaderEditView() {}
    }
}
