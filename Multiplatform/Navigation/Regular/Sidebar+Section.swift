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
        
        init(provider: DataProvider) {
            self.provider = provider
            _expanded = Default(.providerExpanded(provider))
        }
        
        var body: some View {
            Section(provider.title, isExpanded: $expanded) {
                ForEach(provider.sections, id: \.hashValue) { section in
                    NavigationLink(value: Selection(provider: provider, section: section)) {
                        Label(section.title!, systemImage: section.icon!)
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
