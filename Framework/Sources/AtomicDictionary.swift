//
//  AtomicDictionary.swift
//  SwiftyUpdateKit
//
//  Created by Masaki Ando on 2024/04/16.
//  Copyright © 2024 Hituzi Ando. All rights reserved.
//

import Foundation

class AtomicDictionary<Key: Hashable, Value> {
    private var dictionary: [Key: Value] = [:]
    private let queue = DispatchQueue(label: "SwiftyUpdateKit.\(UUID().uuidString)",
                                      attributes: .concurrent)

    func setValue(_ value: Value, forKey key: Key) {
        queue.sync(flags: .barrier) {
            dictionary[key] = value
        }
    }

    func value(forKey key: Key) -> Value? {
        queue.sync {
            dictionary[key]
        }
    }

    @discardableResult
    func removeValue(forKey key: Key) -> Value? {
        queue.sync(flags: .barrier) {
            dictionary.removeValue(forKey: key)
        }
    }
}

let sharedDictionary = AtomicDictionary<String, Any>()
