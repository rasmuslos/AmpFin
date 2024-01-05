//
//  IntentHandler.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 05.01.24.
//

import Intents

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        print("d")
        return IntentHandler()
    }
}

extension IntentHandler: INPlayMediaIntentHandling {
    func handle(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse {
        print("e")
        return .init(code: .handleInApp, userActivity: nil)
    }
}
