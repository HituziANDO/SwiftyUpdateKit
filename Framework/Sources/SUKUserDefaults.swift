//
//  SUKUserDefaults.swift
//  SwiftyUpdateKit
//
//  Created by Masaki Ando on 2023/01/12.
//  Copyright © 2023 Hituzi Ando. All rights reserved.
//

import Foundation

class SUKUserDefaults {
    enum Environment {
        case production
        case development
        case test
    }

    private let env: Environment

    private init(env: Environment) {
        self.env = env
    }

    /// Shared instance. Default is for production.
    private static var instance = SUKUserDefaults(env: .production)

    /// Returns shared instance.
    static var standard: SUKUserDefaults {
        instance
    }

    /// Recreate SUKUserDefaults instance for specified environment.
    static func setEnvironment(_ env: Environment) {
        instance = SUKUserDefaults(env: env)
    }

    func set(_ value: Int, forKey key: String) {
        UserDefaults.standard.set(value, forKey: forEnv(key))
    }

    func set(_ value: String, forKey key: String) {
        UserDefaults.standard.set(value, forKey: forEnv(key))
    }

    func integer(forKey key: String) -> Int {
        UserDefaults.standard.integer(forKey: forEnv(key))
    }

    func string(forKey key: String) -> String? {
        UserDefaults.standard.string(forKey: forEnv(key))
    }

    func removeObject(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: forEnv(key))
    }
}

private extension SUKUserDefaults {

    /// Returns a key for current environment.
    func forEnv(_ key: String) -> String {
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
