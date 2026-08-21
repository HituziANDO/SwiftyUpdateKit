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
        // Synchronous barriers make mutations visible on return. Code already executing on this
        // queue must not call a mutating method recursively because dispatch_sync cannot re-enter.
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
