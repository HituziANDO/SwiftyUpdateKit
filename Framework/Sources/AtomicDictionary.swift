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
        queue.async(flags: .barrier) {
            self.dictionary[key] = value
        }
    }

    func value(forKey key: Key) -> Value? {
        var result: Value?
        queue.sync {
            result = dictionary[key]
        }
        return result
    }

    @discardableResult
    func removeValue(forKey key: Key) -> Value? {
        var result: Value?
        queue.sync {
            result = dictionary.removeValue(forKey: key)
        }
        return result
    }
}

let sharedDictionary = AtomicDictionary<String, Any>()
