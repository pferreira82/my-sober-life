//
//  Item.swift
//  Be The Change
//
//  Created by Peter Ferreira on 11/12/24.
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
