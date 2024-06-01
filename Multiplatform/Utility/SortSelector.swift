//
//  SortSelector.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import Defaults
import AmpFinKit

internal struct SortSelector: View {
    @Default(.sortOrder) private var sortOrder
    @Default(.sortAscending) private var ascending
    
    @Environment(\.libraryDataProvider) private var dataProvider
    
    private var supported: [ItemSortOrder] {
        if dataProvider.supportsAdvancedFilters {
            return ItemSortOrder.allCases
        } else {
            return [.name, .album, .albumArtist, .artist, .added, .released, .random]
        }
    }
    
    var body: some View {
        Menu {
            ForEach(supported, id: \.hashValue) { option in
                Toggle(option.title, isOn: .init(get: { sortOrder == option }, set: {
                    if $0 {
                        sortOrder = option
                    }
                }))
            }
            
            Divider()
            
            Toggle("ascending", isOn: $ascending)
        } label: {
            Label("sort", systemImage: "arrow.up.arrow.down")
                .labelStyle(.iconOnly)
                .symbolVariant(ascending ? .circle.fill : .circle)
        }
    }
}

private extension ItemSortOrder {
    var title: LocalizedStringKey {
        switch self {
            case .added:
                "sort.added"
            case .album:
                "sort.album"
            case .albumArtist:
                "sort.albumArtist"
            case .artist:
                "sort.artist"
            case .name:
                "sort.name"
            case .plays:
                "sort.plays"
            case .lastPlayed:
                "sort.lastPlayed"
            case .released:
                "sort.released"
            case .runtime:
                "sort.runtime"
            case .random:
                "sort.random"
        }
    }
}

#Preview {
    SortSelector()
}
