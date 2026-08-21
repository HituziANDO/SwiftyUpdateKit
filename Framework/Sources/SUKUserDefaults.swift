//
//  SUKUserDefaults.swift
//  SwiftyUpdateKit
//
//  Created by Masaki Ando on 2023/01/12.
//  Copyright © 2023 Hituzi Ando. All rights reserved.
//

import Foundation

class SUKUserDefaults {
    enum Environment: Hashable {
        case production
        case development
        case test
    }

    let env: Environment

    fileprivate init(env: Environment) {
        self.env = env
    }

    /// Returns shared instance.
    static var standard: SUKUserDefaults {
        sharedSUKRuntimeState.snapshot().userDefaults
    }

    /// Recreate SUKUserDefaults instance for specified environment.
    static func setEnvironment(_ env: Environment) {
        sharedSUKRuntimeState.setEnvironment(env)
    }

    func set(_ value: Int, forKey key: String) {
        UserDefaults.standard.set(value, forKey: storageKey(forKey: key))
    }

    func set(_ value: String, forKey key: String) {
        UserDefaults.standard.set(value, forKey: storageKey(forKey: key))
    }

    func integer(forKey key: String) -> Int {
        UserDefaults.standard.integer(forKey: storageKey(forKey: key))
    }

    func string(forKey key: String) -> String? {
        UserDefaults.standard.string(forKey: storageKey(forKey: key))
    }

    func removeObject(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: storageKey(forKey: key))
    }

    /// Returns a storage key for the current environment.
    func storageKey(forKey key: String) -> String {
        switch env {
            case .production:
                return key
            case .development:
                return "\(key).dev"
            case .test:
                return "\(key).test"
        }
    }
}

struct SUKRuntimeContext {
    let config: SwiftyUpdateKitConfig?
    let log: Log?
    let userDefaults: SUKUserDefaults
}

final class SUKRuntimeState {
    private let lock = NSLock()
    private var context = SUKRuntimeContext(config: nil,
                                            log: nil,
                                            userDefaults: SUKUserDefaults(env: .production))

    func initialize(config: SwiftyUpdateKitConfig, log: Log?) {
        lock.lock()
        defer { lock.unlock() }

        context = SUKRuntimeContext(config: config,
                                    log: log,
                                    userDefaults: SUKUserDefaults(env: config
                                        .isDevelopment ? .development : .production))
    }

    func setEnvironment(_ environment: SUKUserDefaults.Environment) {
        lock.lock()
        defer { lock.unlock() }

        context = SUKRuntimeContext(config: context.config,
                                    log: context.log,
                                    userDefaults: SUKUserDefaults(env: environment))
    }

    func snapshot() -> SUKRuntimeContext {
        lock.lock()
        defer { lock.unlock() }

        return context
    }
}

let sharedSUKRuntimeState = SUKRuntimeState()
