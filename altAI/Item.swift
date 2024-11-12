//
//  Item.swift
//  altAI
//
//  Created by Daniel Wentsch on 11.11.24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
