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
        
        private var size: CGFloat {
            if album == nil {
                return 48
            }
            
            return 20
        }
        
        private var active: Bool {
            AudioPlayer.current.nowPlaying == track
        }
        
        var body: some View {
            Group {
                if album != nil {
                    Text(String(track.index.index))
                        .bold(track.favorite)
                        .fixedSize()
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                        .opacity(active ? 0 : 1)
                } else {
                    ItemImage(cover: track.cover)
                }
            }
            .id(track.id)
            .frame(width: size, height: size)
            .overlay {
                ZStack {
                    if album == nil {
                        Color.black.opacity(0.2)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // apparently SwiftUI cannot cope with this symbol effect and enabling it causes all animations to have an abysmal frame-rate... I have no idea why though
                    Image(systemName: "waveform")
                        .font(album == nil ? .body : .caption)
                        .foregroundStyle(album == nil ? .white : .secondary)
                }
                .opacity(active ? 1 : 0)
            }
            .padding(.trailing, 8)
        }
    }
}
