//
//  Sidebar+Section.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 08.04.24.
//

import SwiftUI
import Defaults

extension SidebarView {
    struct ProviderSection: View {
        @Default private var expanded: Bool
        
        let provider: DataProvider
        @Binding var selection: Selection
        
        init(provider: DataProvider, selection: Binding<Selection>) {
            self.provider = provider
            
            _selection = selection
            _expanded = Default(.providerExpanded(provider))
        }
        
        var body: some View {
            Section(provider.title, isExpanded: $expanded) {
                ForEach(provider.sections, id: \.hashValue) { section in
                    NavigationLink {
                        section.content
                            .environment(\.libraryDataProvider, provider.libraryProvider)
                            .onAppear {
                                selection = .init(provider: provider, section: section)
                            }
                    } label: {
                        Label(section.title, systemImage: "command")
                    }
                }
            }
        }
    }
}

private extension Defaults.Keys {
    static func providerExpanded(_ provider: SidebarView.DataProvider) -> Key<Bool> {
        .init("providerExpanded_\(provider.hashValue)", default: true)
    }
}
