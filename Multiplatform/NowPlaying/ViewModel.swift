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
        @MainActor var namespace: Namespace.ID!
        @MainActor var dragOffset: CGFloat
        
        @MainActor private(set) var presented: Bool
        
        @MainActor var controlsVisible: Bool
        @MainActor private(set) var currentTab: NowPlaying.Tab
        
        @MainActor var controlsDragging: Bool
        @MainActor var addToPlaylistSheetPresented: Bool
        
        @MainActor private(set) var colors: [Color]
        @MainActor private(set) var highlights: [Color]
        
        @MainActor var mediaInfoToggled = false
        @MainActor var mediaInfo: Track.MediaInfo? = nil
        
        @MainActor var seekDragging: Bool
        @MainActor var volumeDragging: Bool
        @MainActor var draggedPercentage = 0.0
        
        @MainActor var animateBackward: Bool
        @MainActor var animateForward: Bool
        
        @MainActor
        init() {
            namespace = nil
            dragOffset = .zero
            
            presented = false
            
            controlsVisible = true
            currentTab = .cover
            
            controlsDragging = false
            addToPlaylistSheetPresented = false
            
            colors = []
            highlights = []
            
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
    @MainActor
    var track: Track? {
        if presented, let track = AudioPlayer.current.nowPlaying {
            return track
        }
        
        return nil
    }
    @MainActor
    var addToPlaylistTrack: Track? {
        guard addToPlaylistSheetPresented else {
            return nil
        }
        
        return track
    }
    
    @MainActor
    var showRoundedCorners: Bool {
        dragOffset != 0
    }
    
    @MainActor
    var displayedProgress: Double {
        seekDragging ? draggedPercentage : playedPercentage
    }
    @MainActor
    var playedPercentage: Double {
        AudioPlayer.current.currentTime / AudioPlayer.current.duration
    }
    
    @MainActor
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
        if let cover = await track?.cover {
            guard let dominantColors = try? await AFVisuals.extractDominantColors(10, cover: cover) else {
                await MainActor.run {
                    self.colors = []
                    self.highlights = []
                }
                
                return
            }
            
            let colors = dominantColors.map { $0.color }
            let highlights = AFVisuals.determineSaturated(AFVisuals.highPassFilter(colors, threshold: 0.5), threshold: 0.3)
            
            await MainActor.run { [colors, highlights] in
                self.highlights = highlights
                self.colors = colors.filter { !highlights.contains($0) }
            }
        }
    }
    func determineQuality() async {
        let mediaInfo = await AudioPlayer.current.mediaInfo
        
        await MainActor.run {
            withAnimation {
                self.mediaInfo = mediaInfo
                mediaInfoToggled = mediaInfo?.lossless ?? false
            }
        }
    }
    
    func select(tab: NowPlaying.Tab) {
        Task { @MainActor in
            controlsVisible = true
            
            withAnimation(.bouncy) {
                if currentTab == tab {
                    currentTab = .cover
                } else {
                    currentTab = tab
                }
            }
        }
    }
    func setNowPlayingViewPresented(_ presented: Bool) {
        Task { @MainActor in
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
    }
    
    func updateProgress(_ position: Double) {
        Task { @MainActor in
            draggedPercentage = position
        }
        
        AudioPlayer.current.currentTime = AudioPlayer.current.duration * position
    }
}
