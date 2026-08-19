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

protocol SchedulingExecutionGating: AnyObject {
    func beginExecution(forKey key: String) -> Bool
    func finishExecution(forKey key: String)
}

final class SchedulingExecutionGate: SchedulingExecutionGating {
    private let lock = NSLock()
    private var runningKeys: Set<String> = []

    func beginExecution(forKey key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        return runningKeys.insert(key).inserted
    }

    func finishExecution(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }

        runningKeys.remove(key)
    }
}

let sharedSchedulingExecutionGate = SchedulingExecutionGate()

struct DailySchedule {
    private let clock: SUKClock
    private let stateStore: SUKSchedulingStateStore
    private let executionGate: SchedulingExecutionGating
    private let key: String

    init(clock: SUKClock,
         stateStore: SUKSchedulingStateStore,
         executionGate: SchedulingExecutionGating = sharedSchedulingExecutionGate,
         key: String)
    {
        self.clock = clock
        self.stateStore = stateStore
        self.executionGate = executionGate
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

    func beginExecution() -> Bool {
        executionGate.beginExecution(forKey: key)
    }

    func finishExecution() {
        executionGate.finishExecution(forKey: key)
    }
}
