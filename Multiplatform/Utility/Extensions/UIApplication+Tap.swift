//
//  UIApplication+Tap.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 16.08.24.
//

import Foundation
import UIKit

internal extension UIApplication {
    func addGestureRecognizer() {
        guard let window = (connectedScenes.first as? UIWindowScene)?.windows.first else { return }
        let gesture = UITapGestureRecognizer(target: window, action: nil)
        
        gesture.requiresExclusiveTouchType = false
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        
        window.addGestureRecognizer(gesture)
    }
    
    static let tapGestureFiredNotification = Notification.Name("io.rfk.ampfin.tapGestureFiredNotification")
}

extension UIApplication: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        NotificationCenter.default.post(name: Self.tapGestureFiredNotification, object: nil)
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
