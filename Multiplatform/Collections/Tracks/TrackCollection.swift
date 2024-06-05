//
//  TrackCollection.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 05.06.24.
//

import SwiftUI
import AmpFinKit
import AFPlayback

struct TrackCollection {}

internal extension TrackCollection {
    typealias LoadCallback = (() -> Void)?
    
    typealias DeleteCallback = ((_ track: Track) -> Void)?
    typealias MoveCallback = ((_ track: Track, _ to: Int) -> Void)?
}

internal extension TrackCollection {
    struct TrackIndexCover: View {
        let track: Track
        let album: Album?
        
        @State private var playing: Bool? = nil
        
        private var size: CGFloat {
            album == nil ? 48 : 24
        }
        
        private var playbackIndicator: some View {
            Image(systemName: "waveform")
                .symbolEffect(.variableColor.iterative, isActive: playing ?? false)
        }
        
        var body: some View {
            Group {
                if album != nil {
                    if playing == true {
                        playbackIndicator
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(String(track.index.index))
                            .bold(track.favorite)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    }
                } else {
                    ItemImage(cover: track.cover)
                        .overlay {
                            if playing == true {
                                ZStack {
                                    Color.black.opacity(0.2)
                                        .clipShape(RoundedRectangle(cornerRadius: 7))
                                    
                                    playbackIndicator
                                        .font(.body)
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                }
            }
            .id(track.id)
            .frame(width: size, height: size)
            .padding(.trailing, 8)
            .transition(.blurReplace)
            .onChange(of: AudioPlayer.current.playing, initial: true) {
                guard AudioPlayer.current.nowPlaying == track else {
                    playing = nil
                    return
                }
                
                playing = AudioPlayer.current.playing
            }
        }
    }
}
