//
//  IntentHandler.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 06.01.24.
//

import Intents

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        return self
    }
}

extension IntentHandler: INAddMediaIntentHandling {
    func handle(intent: INAddMediaIntent) async -> INAddMediaIntentResponse {
        if intent.mediaSearch?.reference == .currentlyPlaying, let destination = intent.mediaDestination {
            switch destination {
            case .playlist(let name):
                return .init(code: .success, userActivity: nil)
            default:
                break
            }
        }
        
        return .init(code: .failure, userActivity: nil)
    }
}
