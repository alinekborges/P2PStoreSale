//
//  Random.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 11/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import Foundation
extension Array {
    func random() -> Element? {
        if isEmpty { return nil }
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}

extension Int {
    func random() -> Int {
        let diceRoll = Int(arc4random_uniform(UInt32(self))) + 1
        return diceRoll
    }
}
