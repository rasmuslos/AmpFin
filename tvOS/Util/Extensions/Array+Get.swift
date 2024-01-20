//
//  Array+Get.swift
//  tvOS
//
//  Created by Rasmus Krämer on 19.01.24.
//

import Foundation

extension Array {
    func get(_ index: Index) -> Element? {
        if self.indices.contains(index) {
            return self[index]
        }
        
        return nil
    }
}
