//
//  LyricsView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.07.24.
//

import SwiftUI
import AmpFinKit

struct LyricsSheet: View {
    let track: Track
    
    @State private var failed = false
    @State private var lyrics: Track.Lyrics = [:]
    
    var body: some View {
        NavigationStack {
            Group {
                if lyrics.isEmpty {
                    if failed {
                        ErrorView()
                    } else {
                        LoadingView()
                            .task {
                                await fetchLyrics(track: track)
                            }
                    }
                } else {
                    ScrollView {
                        HStack {
                            VStack(alignment: .leading) {
                                ForEach(Array(lyrics.values), id: \.?.hashValue) { text in
                                    if let text, !text.isEmpty {
                                        Text(text)
                                            .font(.headline)
                                            .fontDesign(.rounded)
                                            .multilineTextAlignment(.leading)
                                            .padding(.vertical, 8)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                    }
                    .safeAreaInset(edge: .top) {
                        ZStack {
                            TrackListRow(track: track, disableMenu: true, startPlayback: {})
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                        }
                        .background(.bar)
                    }
                }
            }
            .refreshable {
                await fetchLyrics(track: track)
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
    }
    
    private nonisolated func fetchLyrics(track: Track) async {
        await MainActor.run {
            failed = false
        }
        
        var lyrics: Track.Lyrics?
        
        if let received = try? OfflineManager.shared.lyrics(trackId: track.id, allowUpdate: true) {
            lyrics = received
        } else if let received = try? await JellyfinClient.shared.lyrics(trackId: track.id) {
            lyrics = received
        }
        
        guard let lyrics else {
            await MainActor.run {
                failed = true
            }
            return
        }
        
        await MainActor.run {
            withAnimation {
                self.lyrics = lyrics
            }
        }
    }
}

#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            LyricsSheet(track: .fixture)
        }
}
