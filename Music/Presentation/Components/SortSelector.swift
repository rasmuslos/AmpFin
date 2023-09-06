//
//  SortSelector.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI

struct SortSelector: View {
    @Binding var sortOrder: JellyfinClient.ItemSortOrder {
        didSet {
            UserDefaults.standard.set(sortOrder.rawValue, forKey: "sortOrder")
        }
    }
    
    var body: some View {
        Menu {
            ForEach(JellyfinClient.ItemSortOrder.allCases, id: \.hashValue) { option in
                Button {
                    sortOrder = option
                } label: {
                    let label = getOptionLabel(option: option)
                    
                    if sortOrder == option {
                        Label(label, systemImage: "checkmark")
                    } else {
                        Text(label)
                    }
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down.circle.fill")
        }
    }
}

// MARK: Helper
extension SortSelector {
    func getOptionLabel(option: JellyfinClient.ItemSortOrder) -> String {
        switch option {
        case .added:
            return "Added"
        case .album:
            return "Album"
        case .albumArtist:
            return "Album Aritst"
        case .artist:
            return "Artist"
        case .name:
            return "Name"
        case .plays:
            return "Plays"
        case .released:
            return "Released"
        case .runtime:
            return "Runtime"
        }
    }
    
    static func getSortOrder() -> JellyfinClient.ItemSortOrder {
        if let stored = UserDefaults.standard.string(forKey: "sortOrder"), let parsed = JellyfinClient.ItemSortOrder(rawValue: stored) {
            return parsed
        }
        return .added
    }
}

#Preview {
    SortSelector(sortOrder: .constant(.added))
}
