//
//  ViewModifier+WindowSize.swift
//  iOS
//
//  Created by Gnattu OC on 4/6/24.
//

import Foundation
import SwiftUI
import UIKit

extension ViewModifier {
    static func getWindowSize() -> CGSize {
        let windowSize = UIApplication.shared.connectedScenes
                        .compactMap({ scene -> UIWindow? in
                            (scene as? UIWindowScene)?.keyWindow
                        })
                        .first?
                        .frame
                        .size
        return windowSize ?? CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
}
