//
//  PlayMediaHandler.swift
//  iOS
//
//  Created by Rasmus Krämer on 05.01.24.
//

import Foundation
import Intents

class PlayMediaHandler: NSObject, INPlayMediaIntentHandling {
    func handle(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse {
        print("e")
        return .init(code: .success, userActivity: nil)
    }
}
