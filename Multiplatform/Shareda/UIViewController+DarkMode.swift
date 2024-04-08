//
//  UIViewController+DarkMode.swift
//  iOS
//
//  Created by Rasmus Krämer on 08.02.24.
//

import Foundation
import UIKit

extension UIViewController {
    var isDarkMode: Bool {
        traitCollection.userInterfaceStyle == .dark
    }
}
