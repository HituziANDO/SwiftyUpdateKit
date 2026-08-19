//
//  DailySchedule.swift
//  SwiftyUpdateKit
//
//  Copyright © 2026 Hituzi Ando. All rights reserved.
//

import Foundation

protocol SUKClock {
    func currentDate() -> Int
}

struct SystemSUKClock: SUKClock {
    func currentDate() -> Int {
        DateUtils.currentDate()
    }
}

protocol SUKSchedulingStateStore {
    func set(_ value: Int, forKey key: String)
    func integer(forKey key: String) -> Int
}

struct UserDefaultsSchedulingStateStore: SUKSchedulingStateStore {
    func set(_ value: Int, forKey key: String) {
        SUKUserDefaults.standard.set(value, forKey: key)
    }

    func integer(forKey key: String) -> Int {
        SUKUserDefaults.standard.integer(forKey: key)
    }
}

struct InMemorySchedulingStateStore: SUKSchedulingStateStore {
    func set(_ value: Int, forKey key: String) {
        sharedDictionary.setValue(value, forKey: key)
    }

    func integer(forKey key: String) -> Int {
        sharedDictionary.value(forKey: key) as? Int ?? 0
    }
}

struct DailySchedule {
    private let clock: SUKClock
    private let stateStore: SUKSchedulingStateStore
    private let key: String

    init(clock: SUKClock, stateStore: SUKSchedulingStateStore, key: String) {
        self.clock = clock
        self.stateStore = stateStore
        self.key = key
    }

    func shouldRun() -> Bool {
        stateStore.integer(forKey: key) < clock.currentDate()
    }

    func hasRecordedDate() -> Bool {
        stateStore.integer(forKey: key) != 0
    }

    func recordCurrentDate() {
        let currentDate = clock.currentDate()
        guard stateStore.integer(forKey: key) < currentDate else { return }

        stateStore.set(currentDate, forKey: key)
    }
}
