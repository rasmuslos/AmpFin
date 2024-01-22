//
//  TracksList.swift
//  tvOS
//
//  Created by Rasmus Krämer on 22.01.24.
//

import SwiftUI
import AFBase
import AFPlayback

struct TracksList: View {
    let tracks: [Track]
    let container: Item?
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(tracks) { track in
                    Button {
                        startPlayback(track: track)
                    } label: {
                        TrackListRow(track: track)
                    }
                    .buttonStyle(.plain)
                    .onPlayPauseCommand {
                        startPlayback(track: track)
                    }
                    .contextMenu {
                        Button {
                            Task {
                                await track.setFavorite(favorite: !track.favorite)
                            }
                        } label: {
                            Label("favorite", systemImage: track.favorite ? "heart.fill" : "heart")
                        }
                        
                        Button {
                            Task {
                                try? await track.startInstantMix()
                            }
                        } label: {
                            Label("queue.mix", systemImage: "compass.drawing")
                        }
                        
                        Divider()
                        
                        Button {
                            startPlayback(track: track)
                        } label: {
                            Text("queue.now")
                        }
                        
                        Button {
                            AudioPlayer.current.queueTrack(track, index: 0)
                        } label: {
                            Text("queue.next")
                        }
                        
                        Button {
                            AudioPlayer.current.queueTrack(track, index: AudioPlayer.current.queue.count)
                        } label: {
                            Text("queue.last")
                        }
                        
                        Divider()
                        
                        // TODO: Album, artist, playlist (add, remove)
                    }
                }
            }
            .padding(.horizontal, 80)
        }
    }
}

extension TracksList {
    func startPlayback(track: Track) {
        AudioPlayer.current.startPlayback(tracks: tracks, startIndex: tracks.firstIndex(of: track)!, shuffle: false, playbackInfo: container == nil ? .init() : .init(container: container!))
    }
}

#Preview {
    TracksList(tracks: [
        Track.fixture,
        Track.fixture,
        Track.fixture,
        Track.fixture,
        Track.fixture,
        Track.fixture,
        Track.fixture,
    ], container: nil)
}
