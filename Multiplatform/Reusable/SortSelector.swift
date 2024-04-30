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
    
    var body: some View {
        Menu {
            ForEach(filter(), id: \.hashValue) { option in
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
                .symbolVariant(ascending ? .circle.fill : .circle)
        }
    }
}

extension SortSelector {
    func filter() -> [JellyfinClient.ItemSortOrder] {
        if dataProvider.supportsAdvancedFilters {
            return JellyfinClient.ItemSortOrder.allCases
        } else {
            return JellyfinClient.ItemSortOrder.allCases.filter { $0 != .added && $0 != .released && $0 != .plays && $0 != .runtime && $0 != .lastPlayed }
        }
    }
}

private extension JellyfinClient.ItemSortOrder {
    var title: LocalizedStringKey {
        switch self {
            case .added:
                return "sort.added"
            case .album:
                return "sort.album"
            case .albumArtist:
                return "sort.albumArtist"
            case .artist:
                return "sort.artist"
            case .name:
                return "sort.name"
            case .plays:
                return "sort.plays"
            case .lastPlayed:
                return "sort.lastPlayed"
            case .released:
                return "sort.released"
            case .runtime:
                return "sort.runtime"
        }
    }
}

#Preview {
    SortSelector(ascending: .constant(true), sortOrder: .constant(.added))
}
