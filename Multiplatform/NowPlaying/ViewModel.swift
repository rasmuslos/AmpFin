//
//  ViewModel.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 26.07.24.
//

import Foundation
import SwiftUI
import AmpFinKit
import AFPlayback

internal extension NowPlaying {
    @Observable
    class ViewModel {
        var namespace: Namespace.ID!
        var dragOffset: CGFloat
        
        private(set) var presented: Bool
        
        var controlsVisible: Bool
        private(set) var currentTab: NowPlaying.Tab
        
        var controlsDragging: Bool
        var addToPlaylistSheetPresented: Bool
        
        private(set) var colors: [Color]
        private(set) var highlighted: Color?
        
        var mediaInfoToggled = false
        var mediaInfo: Track.MediaInfo? = nil
        
        var seekDragging: Bool
        var volumeDragging: Bool
        var draggedPercentage = 0.0
        
        var animateBackward: Bool
        var animateForward: Bool
        
        init() {
            namespace = nil
            dragOffset = .zero
            
            presented = false
            
            controlsVisible = true
            currentTab = .cover
            
            controlsDragging = false
            addToPlaylistSheetPresented = false
            
            colors = []
            highlighted = nil
            
            mediaInfoToggled = false
            mediaInfo = nil
            
            seekDragging = false
            volumeDragging = false
            draggedPercentage = 0
            
            animateBackward = false
            animateForward = false
        }
    }
}

internal extension NowPlaying.ViewModel {
    var track: Track? {
        if presented, let track = AudioPlayer.current.nowPlaying {
            return track
        }
        
        return nil
    }
    var addToPlaylistTrack: Track? {
        guard addToPlaylistSheetPresented else {
            return nil
        }
        
        return track
    }
    
    var showRoundedCorners: Bool {
        dragOffset != 0
    }
    
    var displayedProgress: Double {
        seekDragging ? draggedPercentage : playedPercentage
    }
    var playedPercentage: Double {
        AudioPlayer.current.currentTime / AudioPlayer.current.duration
    }
    
    var qualityText: String? {
        if let mediaInfo = mediaInfo {
            var result = [String]()
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            formatter.usesGroupingSeparator = true
            
            if mediaInfoToggled && (mediaInfo.bitDepth != nil || mediaInfo.sampleRate != nil) {
                if let bitDepth = mediaInfo.bitDepth {
                    result.append(formatter.string(from: .init(value: bitDepth))!)
                }
                if let sampleRate = mediaInfo.sampleRate {
                    result.append(formatter.string(from: .init(value: sampleRate))!)
                }
            } else {
                if let codec = mediaInfo.codec {
                    result.append(codec.uppercased())
                }
                if let bitrate = mediaInfo.bitrate {
                    result.append(formatter.string(from: .init(value: bitrate / 1000))!)
                }
            }
            
            if result.isEmpty {
                return nil
            }
            
            return result.joined(separator: " - ")
        }
        
        return nil
    }
}

internal extension NowPlaying.ViewModel {
    func trackDidChange() async {
        await withTaskGroup(of: Void.self) {
            $0.addTask { await self.determineColors() }
            $0.addTask { await self.determineQuality() }
        }
    }
    func determineColors() async {
        if let cover = track?.cover {
            guard let dominantColors = try? await AFVisuals.extractDominantColors(10, cover: cover) else {
                await MainActor.run {
                    self.colors = []
                    self.highlighted = nil
                }
                
                return
            }
            
            let colors = dominantColors.map { $0.color }
            let mostSaturated = AFVisuals.determineSaturated(colors)
            
            await MainActor.run { [colors, mostSaturated] in
                self.colors = colors.filter { $0 != highlighted }
                self.highlighted = mostSaturated
            }
        }
    }
    func determineQuality() async {
        if let mediaInfo = await AudioPlayer.current.mediaInfo {
            self.mediaInfo = mediaInfo
            mediaInfoToggled = mediaInfo.lossless ?? false
        } else {
            mediaInfo = nil
        }
    }
    
    func select(tab: NowPlaying.Tab) {
        controlsVisible = true
        
        withAnimation(.bouncy) {
            currentTab = tab
        }
    }
    func setNowPlayingViewPresented(_ presented: Bool) {
        if presented {
            dragOffset = 0
        }
        if currentTab != .lyrics || presented {
            controlsVisible = true
        }
        
        addToPlaylistSheetPresented = false
        
        UIApplication.shared.isIdleTimerDisabled = presented
        
        withTransaction(\.nowPlayingOverlayToggled, true) {
            withAnimation(presented ? .bouncy.delay(0.25) : .bouncy) {
                self.presented = presented
            }
        }
    }
    
    func updateProgress(_ to: Double) {
        draggedPercentage = to
        AudioPlayer.current.currentTime = AudioPlayer.current.duration * to
    }
}
