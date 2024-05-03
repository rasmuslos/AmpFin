//
//  SortSelector.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AFBase

struct SortSelector: View {
    @Environment(\.libraryDataProvider) private var dataProvider
    
    @Binding var ascending: Bool
    @Binding var sortOrder: JellyfinClient.ItemSortOrder
    
    private var supported: [JellyfinClient.ItemSortOrder] {
        if dataProvider.supportsAdvancedFilters {
            return JellyfinClient.ItemSortOrder.allCases
        } else {
            return [.name, .album, .albumArtist, .artist, .added, .released]
        }
    }
    
    var body: some View {
        Menu {
            ForEach(supported, id: \.hashValue) { option in
                Button {
                    withAnimation {
                        sortOrder = option
                    }
                } label: {
                    if sortOrder == option {
                        #if targetEnvironment(macCatalyst)
                        Toggle(option.title, isOn: .constant(true))
                        #else
                        Label(option.title, systemImage: "checkmark")
                        #endif
                    } else {
                        Text(option.title)
                    }
                }
            }
            
            Divider()
            
            Button {
                withAnimation {
                    ascending.toggle()
                }
            } label: {
                if ascending {
                    #if targetEnvironment(macCatalyst)
                    Toggle("ascending", isOn: $ascending)
                    #else
                    Label("ascending", systemImage: "checkmark")
                    #endif
                } else {
                    Text("ascending")
                }
            }
        } label: {
            Label("sort", systemImage: "arrow.up.arrow.down")
                .labelStyle(.iconOnly)
                .symbolVariant(ascending ? .circle.fill : .circle)
        }
    }
}

private extension JellyfinClient.ItemSortOrder {
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
    SortSelector(ascending: .constant(true), sortOrder: .constant(.added))
}
