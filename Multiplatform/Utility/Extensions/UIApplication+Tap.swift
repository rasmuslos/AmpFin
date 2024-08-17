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
        
        let tapGesture = UITapGestureRecognizer(target: window, action: nil)
        
        tapGesture.requiresExclusiveTouchType = false
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        
        window.addGestureRecognizer(tapGesture)
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
