//
//  DebugTokenTimelineProvider.swift
//  widget Extension
//
//  Created by Rasmus Krämer on 05.01.24.
//

import SwiftUI
import WidgetKit
import AFBase

struct DebugTokenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "io.rfk.ampfin.debug.token",
            provider: DebugTokenTimelineProvider()) { entry in
                Text(entry.token)
                    .containerBackground(.ultraThickMaterial, for: .widget)
            }
            .configurationDisplayName(String(localized: "debug.title"))
            .description(String(localized: "debug.description"))
    }
}

struct DebugTokenTimelineProvider: TimelineProvider {
    typealias Entry = DebugTokenEntry
    
    func placeholder(in context: Context) -> DebugTokenEntry {
        DebugTokenEntry(date: Date())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(DebugTokenEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        completion(Timeline(entries: [DebugTokenEntry(date: Date())], policy: .never))
    }
}

struct DebugTokenEntry: TimelineEntry {
    var date: Date
    let token = JellyfinClient.shared.token ?? String(localized: "token.missing")
}

#Preview(as: .systemSmall) {
    DebugTokenWidget()
} timeline: {
    DebugTokenEntry(date: Date())
}
