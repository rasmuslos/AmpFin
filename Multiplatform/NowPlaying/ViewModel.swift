//
//  ViewModel.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 26.07.24.
//

import Foundation
import SwiftUI
import RFKVisuals
import AmpFinKit
import AFPlayback

internal extension NowPlaying {
    @Observable
    class ViewModel {
        // MARK: Presentation
        
        @ObservationIgnored var namespace: Namespace.ID!
        @MainActor var _dragOffset: CGFloat
        
        @MainActor private(set) var expanded: Bool
        @MainActor var queueTab: QueueTab? = .queue
        @MainActor private(set) var currentTab: NowPlaying.Tab
        
        // MARK: Current presentation state
        
        @MainActor var mediaInfoToggled = false
        @MainActor var addToPlaylistTrack: Track?
        
        // MARK: Sliders
        
        @MainActor var seekDragging: Bool
        @MainActor var volumeDragging: Bool
        @MainActor var controlsDragging: Bool
        
        @MainActor var draggedPercentage = 0.0
        
        // MARK: Background
        
        @MainActor private(set) var colors: [Color]
        @MainActor private(set) var highlights: [Color]
        @MainActor private var extractedCoverItemID: String?
        
        // MARK: Current state
        
        @MainActor private(set) var source: AudioPlayer.PlaybackSource
        @MainActor private(set) var playbackInfo: PlaybackInfo?
        
        @MainActor private(set) var playing: Bool
        
        @MainActor private(set) var duration: Double
        @MainActor private(set) var currentTime: Double
        
        @MainActor private(set) var history: [Track]
        @MainActor private(set) var nowPlaying: Track?
        
        @MainActor private(set) var queue: [Track]
        @MainActor private(set) var infiniteQueue: [Track]?
        
        @MainActor private(set) var buffering: Bool
        
        @MainActor private(set) var shuffled: Bool
        @MainActor private(set) var repeatMode: RepeatMode
        
        @MainActor private(set) var mediaInfo: Track.MediaInfo?
        @MainActor private(set) var outputRoute: AudioPlayer.AudioRoute
        
        @MainActor private(set) var allowQueueLater: Bool
        
        // MARK: Lyrics
        
        @MainActor private(set) var lyrics: Track.Lyrics
        @MainActor private(set) var lyricsFetchFailed: Bool
        
        @MainActor private(set) var activeLineIndex: Int
        
        @MainActor private(set) var scrolling: Bool
        @MainActor private(set) var _controlsVisible: Bool
        
        @ObservationIgnored private var scrollTimeout: Task<Void, Error>?
        
        // MARK: Helper
        
        @MainActor private(set) var notifyPlaying: Int
        @MainActor private(set) var notifyForwards: Int
        @MainActor private(set) var notifyBackwards: Int
        
        @ObservationIgnored private var tokens = [Any]()
        
        @MainActor
        init() {
            namespace = nil
            _dragOffset = .zero
            
            expanded = false
            currentTab = .cover
            
            mediaInfoToggled = false
            addToPlaylistTrack = nil
            
            seekDragging = false
            volumeDragging = false
            controlsDragging = false
            
            draggedPercentage = 0
            
            colors = []
            highlights = []
            
            source = AudioPlayer.current.source
            
            playing = AudioPlayer.current.playing
            
            duration = AudioPlayer.current.duration
            currentTime = AudioPlayer.current.currentTime
            
            history = AudioPlayer.current.history
            nowPlaying = AudioPlayer.current.nowPlaying
            queue = AudioPlayer.current.queue
            
            buffering = AudioPlayer.current.buffering
            
            shuffled = AudioPlayer.current.shuffled
            repeatMode = AudioPlayer.current.repeatMode
            
            mediaInfo = nil
            outputRoute = AudioPlayer.current.outputRoute
            
            allowQueueLater = AudioPlayer.current.allowQueueLater
            
            lyrics = [:]
            lyricsFetchFailed = false
            
            activeLineIndex = 0
            
            scrolling = true
            _controlsVisible = true
            
            scrollTimeout = nil
            
            notifyPlaying = 0
            notifyForwards = 0
            notifyBackwards = 0
            
            setupObservers()
        }
    }
    
    enum QueueTab: Hashable, Identifiable, Equatable, CaseIterable {
        case history
        case queue
        case infiniteQueue
        
        var id: Self {
            self
        }
    }
}

// MARK: Properties

internal extension NowPlaying.ViewModel {
    @MainActor
    var dragOffset: CGFloat {
        get {
            if !expanded || controlsDragging || _dragOffset < 40 {
                return 0
            }
            
            return _dragOffset
        }
        set {
            self._dragOffset = newValue
        }
    }
    
    @MainActor
    var track: Track? {
        if expanded, let track = nowPlaying {
            return track
        }
        
        return nil
    }
    
    @MainActor
    var controlsVisible: Bool {
        guard currentTab == .lyrics && !lyricsFetchFailed && !lyrics.isEmpty else {
            return true
        }
        
        return _controlsVisible
    }
    
    @MainActor
    var backgroundCornerRadius: CGFloat {
        guard expanded else {
            return 16
        }
        
        if dragOffset > 0 {
            return UIScreen.main.displayCornerRadius
        }
        
        return 0
    }
    
    @MainActor
    var displayedProgress: Double {
        seekDragging ? draggedPercentage : playedPercentage
    }
    @MainActor
    var playedPercentage: Double {
        currentTime / duration
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
    
    @MainActor
    var lyricsKeys: [Double] {
        Array(lyrics.keys).sorted(by: <)
    }
    
    @MainActor
    var lyricsLoaded: Bool {
        !lyrics.isEmpty && !lyricsKeys.isEmpty
    }
}

// MARK: Observers

private extension NowPlaying.ViewModel {
    // This is truly swift the way it was intended to be
    func setupObservers() {
        for token in tokens {
            NotificationCenter.default.removeObserver(token)
        }
        
        tokens = []
        
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.sourceDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor in
                self?.source = AudioPlayer.current.source
            }
        })
        
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.trackDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task {
                await MainActor.withAnimation { [weak self] in
                    let nowPlaying = self?.nowPlaying
                    
                    self?.mediaInfo = nil
                    self?.nowPlaying = AudioPlayer.current.nowPlaying
                    
                    if nowPlaying == nil && self?.nowPlaying != nil {
                        self?.setPresented(true)
                    } else if self?.nowPlaying == nil {
                        self?.setPresented(false)
                    }
                }
                
                await withTaskGroup(of: Void.self) {
                    // MARK: Fetch media info
                    $0.addTask { await self?.updateMediaInfo() }
                    // MARK: extract colors
                    $0.addTask {
                        if let cover = await self?.track?.cover {
                            guard let dominantColors = try? await RFKVisuals.extractDominantColors(10, url: cover.url) else {
                                await MainActor.withAnimation { [weak self] in
                                    self?.colors = []
                                    self?.highlights = []
                                }
                                
                                return
                            }
                            
                            let colors = dominantColors.map { $0.color }
                            var highlights = RFKVisuals.highPassFilter(colors, threshold: 0.4)
                            
                            if highlights.isEmpty {
                                highlights = [.yellow, .red, .orange, .blue, .green, .purple]
                            }
                            
                            let count = highlights.count
                            
                            for i in 0..<count {
                                if Int.random(in: 0...1) == 1 {
                                    highlights.append(highlights[i])
                                }
                            }
                            
                            let extractedCoverItemID = await self?.extractedCoverItemID
                            let itemID = await self?.nowPlaying?.id
                            
                            guard !Task.isCancelled && extractedCoverItemID != itemID else {
                                return
                            }
                            
                            await MainActor.withAnimation { [colors, highlights, weak self] in
                                self?.highlights = highlights.map { RFKVisuals.adjust($0, saturation: 0.5, brightness: 0.5) }
                                self?.colors = colors.filter { !highlights.contains($0) }
                                self?.extractedCoverItemID = itemID
                            }
                        }
                    }
                    // MARK: Fetch Lyrics
                    $0.addTask {
                        await MainActor.withAnimation { [weak self] in
                            self?.lyrics = [:]
                            self?.setActiveLine(0)
                        }
                        
                        let trackId = AudioPlayer.current.nowPlaying?.id
                        
                        await MainActor.withAnimation { [weak self] in
                            self?.lyricsFetchFailed = trackId == nil
                        }
                        
                        guard let trackId else {
                            return
                        }
                        
                        var lyrics = try? OfflineManager.shared.lyrics(trackId: trackId, allowUpdate: true)
                        
                        if lyrics == nil {
                            lyrics = try? await JellyfinClient.shared.lyrics(trackId: trackId)
                        }
                        
                        await MainActor.withAnimation { [lyrics, weak self] in
                            self?.lyricsFetchFailed = lyrics == nil
                            self?.lyrics = lyrics ?? [:]
                        }
                        
                        self?.setActiveLine(0)
                        self?.updateLyricsIndex()
                    }
                }
            }
        })
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.playingDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.playing = AudioPlayer.current.playing
                self?.notifyPlaying += 1
            }
        })
        
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.bufferingDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.buffering = AudioPlayer.current.buffering
            }
        })
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.playbackInfoDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.playbackInfo = AudioPlayer.current.playbackInfo
            }
        })
        
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.timeDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.duration = AudioPlayer.current.duration
                self?.currentTime = AudioPlayer.current.currentTime
                
                self?.updateLyricsIndex()
            }
        })
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.queueDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                withAnimation {
                    self?.history = AudioPlayer.current.history
                    self?.queue = AudioPlayer.current.queue
                    self?.infiniteQueue = AudioPlayer.current.infiniteQueue
                    
                    self?.allowQueueLater = AudioPlayer.current.allowQueueLater
                    
                    if self?.queue.isEmpty == true && self?.history.isEmpty == true && self?.infiniteQueue?.isEmpty ?? true {
                        self?.queueTab = .queue
                    }
                    
                    self?.shuffled = AudioPlayer.current.shuffled
                    self?.repeatMode = AudioPlayer.current.repeatMode
                }
            }
        })
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.queueModeDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                withAnimation {
                    self?.shuffled = AudioPlayer.current.shuffled
                    self?.repeatMode = AudioPlayer.current.repeatMode
                }
            }
        })
        
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.bitrateDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.updateMediaInfo()
            }
        })
        
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.routeDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.outputRoute = AudioPlayer.current.outputRoute
            }
        })
        
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.forwardsNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.notifyForwards += 1
            }
        })
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.backwardsNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.notifyBackwards += 1
            }
        })
    }
    func updateMediaInfo() async {
        let mediaInfo = await AudioPlayer.current.mediaInfo
        
        await MainActor.withAnimation {
            self.mediaInfo = mediaInfo
            self.mediaInfoToggled = mediaInfo?.lossless ?? false
        }
    }
}

// MARK: Setter

internal extension NowPlaying.ViewModel {
    func selectTab(_ tab: NowPlaying.Tab) {
        Task { @MainActor in
            _controlsVisible = true
            
            withAnimation(.bouncy) {
                if currentTab == tab {
                    currentTab = .cover
                } else {
                    currentTab = tab
                }
            }
            
            updateLyricsIndex()
            startScrollTimer()
        }
    }
    func setPresented(_ presented: Bool) {
        Task { @MainActor in
            if presented {
                dragOffset = 0
            }
            
            _controlsVisible = true
            addToPlaylistTrack = nil
            
            UIApplication.shared.isIdleTimerDisabled = presented
            
            self.expanded = presented
        }
    }
    
    func setPosition(percentage: Double) {
        Task { @MainActor in
            draggedPercentage = percentage
        }
        
        AudioPlayer.current.currentTime = AudioPlayer.current.duration * percentage
    }
}

// MARK: Lyrics

internal extension NowPlaying.ViewModel {
    @MainActor
    func scroll(_ proxy: ScrollViewProxy, anchor: UnitPoint) {
        if scrolling && !controlsDragging {
            return
        }
        
        withAnimation(.spring) {
            proxy.scrollTo(activeLineIndex, anchor: anchor)
        }
    }
    
    func didInteract() {
        Task { @MainActor in
            guard currentTab == .lyrics && !controlsDragging else {
                return
            }
            
            withAnimation {
                scrolling = true
                _controlsVisible = true
            }
        }
        
        startScrollTimer()
    }
    
    func startScrollTimer() {
        scrollTimeout?.cancel()
        scrollTimeout = Task {
            try await Task.sleep(nanoseconds: UInt64(4) * NSEC_PER_SEC)
            try Task.checkCancellation()
            
            guard await controlsDragging == false, await currentTab == .lyrics else {
                return
            }
            
            await MainActor.withAnimation {
                self._controlsVisible = false
                self.scrolling = false
            }
        }
    }
    
    func setActiveLine(_ index: Int) {
        Task { @MainActor in
            withAnimation(.spring) {
                activeLineIndex = index
            }
        }
    }
    func updateLyricsIndex() {
        Task { @MainActor in
            guard !lyricsKeys.isEmpty else {
                setActiveLine(0)
                return
            }
            
            let currentTime = AudioPlayer.current.currentTime
            
            if let index = lyricsKeys.lastIndex(where: { $0 <= currentTime }) {
                setActiveLine(index)
            } else {
                setActiveLine(0)
            }
        }
    }
}
