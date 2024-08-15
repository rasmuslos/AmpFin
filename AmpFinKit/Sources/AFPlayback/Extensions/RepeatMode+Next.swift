//
//  RepeatMode+Next.swift
//  AmpFin
//
// Created by Rasmus Krämer on 15.08.24 at 11:08.
// 
    
import Foundation
import AFFoundation

public extension RepeatMode {
    var next: RepeatMode {
        switch self {
            case .none:
                return .queue
            case .queue:
                return .track
            case .track:
                if AudioPlayer.current.infiniteQueue == nil {
                    return .none
                }
                
                return .infinite
            case .infinite:
                return .none
        }
    }
}
