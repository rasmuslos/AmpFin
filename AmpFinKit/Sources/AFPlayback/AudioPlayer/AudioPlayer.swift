//
//  Playback.swift
//  MusicKit
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import MediaPlayer
import OSLog
import Defaults
import AFFoundation
import AFExtension
import AFNetwork

#if canImport(AFOffline)
import AFOffline
#endif

@Observable
public final class AudioPlayer {
    static let logger = Logger(subsystem: "io.rfk.ampfin", category: "AudioPlayer")
    
    public var playbackInfo: PlaybackInfo? {
        didSet {
            guard oldValue != playbackInfo else {
                return
            }
            
            NotificationCenter.default.post(name: AudioPlayer.playbackInfoDidChangeNotification, object: nil)
        }
    }
    
    public internal(set) var source: PlaybackSource = .none {
        didSet {
            guard oldValue != source else {
                return
            }
            
            MPRemoteCommandCenter.shared().likeCommand.isEnabled = source == .local
            checkRemoteControlAvailability()
            
            NotificationCenter.default.post(name: Self.sourceDidChangeNotification, object: nil)
        }
    }
    public var allowRemoteControl = false {
        didSet {
            guard oldValue != allowRemoteControl else {
                return
            }
            
            checkRemoteControlAvailability()
        }
    }
    
    internal var endpoint: AudioEndpoint?
    
    init() {
        Task {
            await self.setupObservers()
            await self.setupRemoteControls()
        }
    }
}

internal extension AudioPlayer {
    func checkRemoteControlAvailability() {
        var remoteControlAvailable = true
        
        if source != .local {
            remoteControlAvailable = false
            return
        }
        
        Task { [remoteControlAvailable] in
            try? await JellyfinClient.shared.update(allowRemoteControl: remoteControlAvailable)
        }
    }
    
    func signalEndpointChange() {
        NotificationCenter.default.post(name: Self.trackDidChangeNotification, object: nil)
        NotificationCenter.default.post(name: Self.playingDidChangeNotification, object: nil)
        NotificationCenter.default.post(name: Self.bufferingDidChangeNotification, object: nil)
        
        NotificationCenter.default.post(name: Self.timeDidChangeNotification, object: nil)
        NotificationCenter.default.post(name: Self.queueDidChangeNotification, object: nil)
        
        NotificationCenter.default.post(name: Self.volumeDidChangeNotification, object: nil)
        NotificationCenter.default.post(name: Self.bitrateDidChangeNotification, object: nil)
        
        NotificationCenter.default.post(name: Self.routeDidChangeNotification, object: nil)
    }
    
    func setupLocalPlayback() {
        stopPlayback()
        
        source = .local
        endpoint = LocalAudioEndpoint.shared
        
        signalEndpointChange()
    }
}

public extension AudioPlayer {
    func startRemoteControl(session: Session) {
        Self.logger.info("Setting up remote endpoint \(session.name) (\(session.client))")
        
        stopPlayback()
        
        JellyfinWebSocket.shared.beginObservingSessionUpdated(clientId: session.clientId)
        source = .jellyfinRemote
        endpoint = RemoteAudioEndpoint(session: session)
        
        signalEndpointChange()
    }
}

public extension AudioPlayer {
    enum PlaybackSource {
        case none
        case local
        case jellyfinRemote
    }
    
    struct AudioRoute {
        public let port: AVAudioSession.Port
        public let name: String
        
        public var showLabel: Bool {
            port == .bluetoothLE || port == .bluetoothHFP || port == .bluetoothA2DP || port == .carAudio || port == .airPlay
        }
        
        public var icon: String {
            if let icon = iconOverride(routeName: name) {
                return icon
            }
            
            switch port {
            case .usbAudio:
                return "cable.connector"
            case .thunderbolt:
                return "bolt"
            case .lineOut:
                return "cable.coaxial"
            case .carAudio:
                return "car"
            case .airPlay:
                return "airplayaudio"
            case .HDMI, .displayPort:
                return "tv"
            case .bluetoothLE, .bluetoothHFP, .bluetoothA2DP:
                return Defaults[.defaultBTDeviceIcon]
            case .headphones:
                return "headphones"
            default:
                return "airplayaudio"
            }
        }
        
        private func iconOverride(routeName: String) -> String? {
            if routeName.contains("WH-1000XM5") || routeName.contains("CRUSHER ANC") {
                return "headphones"
            }
            
            return nil
        }
    }
}

public extension AudioPlayer {
    static let current = AudioPlayer()
}
