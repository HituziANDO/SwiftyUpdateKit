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

struct SchedulingStateContext {
    let userDefaults: SUKUserDefaults
    let key: String

    var storageKey: String {
        userDefaults.storageKey(forKey: key)
    }
}

protocol SUKSchedulingStateStore {
    func set(_ value: Int, forKey key: String)
    func integer(forKey key: String) -> Int
    func removeValue(forKey key: String)
    func set(_ value: Int, for context: SchedulingStateContext)
    func integer(for context: SchedulingStateContext) -> Int
    func removeValue(for context: SchedulingStateContext)
}

extension SUKSchedulingStateStore {
    func set(_ value: Int, for context: SchedulingStateContext) {
        set(value, forKey: context.key)
    }

    func integer(for context: SchedulingStateContext) -> Int {
        integer(forKey: context.key)
    }

    func removeValue(for context: SchedulingStateContext) {
        removeValue(forKey: context.key)
    }
}

struct UserDefaultsSchedulingStateStore: SUKSchedulingStateStore {
    func set(_ value: Int, forKey key: String) {
        SUKUserDefaults.standard.set(value, forKey: key)
    }

    func integer(forKey key: String) -> Int {
        SUKUserDefaults.standard.integer(forKey: key)
    }

    func removeValue(forKey key: String) {
        SUKUserDefaults.standard.removeObject(forKey: key)
    }

    func set(_ value: Int, for context: SchedulingStateContext) {
        context.userDefaults.set(value, forKey: context.key)
    }

    func integer(for context: SchedulingStateContext) -> Int {
        context.userDefaults.integer(forKey: context.key)
    }

    func removeValue(for context: SchedulingStateContext) {
        context.userDefaults.removeObject(forKey: context.key)
    }
}

struct InMemorySchedulingStateStore: SUKSchedulingStateStore {
    func set(_ value: Int, forKey key: String) {
        sharedDictionary.setValue(value, forKey: storageKey(forKey: key))
    }

    func integer(forKey key: String) -> Int {
        sharedDictionary.value(forKey: storageKey(forKey: key)) as? Int ?? 0
    }

    func removeValue(forKey key: String) {
        sharedDictionary.removeValue(forKey: storageKey(forKey: key))
    }

    func set(_ value: Int, for context: SchedulingStateContext) {
        sharedDictionary.setValue(value, forKey: context.storageKey)
    }

    func integer(for context: SchedulingStateContext) -> Int {
        sharedDictionary.value(forKey: context.storageKey) as? Int ?? 0
    }

    func removeValue(for context: SchedulingStateContext) {
        sharedDictionary.removeValue(forKey: context.storageKey)
    }

    private func storageKey(forKey key: String) -> String {
        SUKUserDefaults.standard.storageKey(forKey: key)
    }
}

private final class SchedulingExecutionTokenBox: NSObject {
    let token: SchedulingExecutionToken

    init(_ token: SchedulingExecutionToken) {
        self.token = token
    }
}

enum SchedulingExecutionScope {
    private static let threadDictionaryKey =
        "jp.hituzi.SwiftyUpdateKit.schedulingExecutionToken"

    static var currentToken: SchedulingExecutionToken? {
        (Thread.current.threadDictionary[threadDictionaryKey]
            as? SchedulingExecutionTokenBox)?.token
    }

    static func withToken<T>(_ token: SchedulingExecutionToken, action: () throws -> T) rethrows
        -> T
    {
        let threadDictionary = Thread.current.threadDictionary
        let previousValue = threadDictionary[threadDictionaryKey]
        threadDictionary[threadDictionaryKey] = SchedulingExecutionTokenBox(token)
        defer {
            if let previousValue {
                threadDictionary[threadDictionaryKey] = previousValue
            } else {
                threadDictionary.removeObject(forKey: threadDictionaryKey)
            }
        }

        return try action()
    }
}

struct SchedulingExecutionToken {
    fileprivate let identifier: UUID
    fileprivate let environment: SUKUserDefaults.Environment
    fileprivate let generation: UInt64
    fileprivate let executionKey: SchedulingExecutionKey?
    let userDefaults: SUKUserDefaults
}

enum SchedulingExecutionDecision {
    case started(SchedulingExecutionToken)
    case inProgress
    case notEligible(SchedulingExecutionToken)
}

protocol SchedulingExecutionGating: AnyObject {
    func token(for userDefaults: SUKUserDefaults) -> SchedulingExecutionToken
    func beginExecution(for context: SchedulingStateContext,
                        preflightToken: SchedulingExecutionToken) -> SchedulingExecutionDecision
    func isCurrent(_ token: SchedulingExecutionToken) -> Bool
    func performStateAccessIfCurrent(_ token: SchedulingExecutionToken,
                                     action: () -> Void) -> Bool
    func finishExecution(_ token: SchedulingExecutionToken)
}

final class SchedulingExecutionGate: SchedulingExecutionGating {
    private let lock = NSLock()
    private var generations: [SUKUserDefaults.Environment: UInt64] = [:]
    private var runningExecutions: [SchedulingExecutionKey: UUID] = [:]

    func token(for userDefaults: SUKUserDefaults) -> SchedulingExecutionToken {
        lock.lock()
        defer { lock.unlock() }

        return makeToken(userDefaults: userDefaults, executionKey: nil)
    }

    func beginExecution(for context: SchedulingStateContext,
                        preflightToken: SchedulingExecutionToken) -> SchedulingExecutionDecision
    {
        lock.lock()
        defer { lock.unlock() }

        guard preflightToken.environment == context.userDefaults.env,
              generations[preflightToken.environment, default: 0] == preflightToken.generation
        else { return .notEligible(preflightToken) }

        let executionKey = SchedulingExecutionKey(environment: context.userDefaults.env,
                                                  storageKey: context.storageKey)
        let token = SchedulingExecutionToken(identifier: UUID(),
                                             environment: preflightToken.environment,
                                             generation: preflightToken.generation,
                                             executionKey: executionKey,
                                             userDefaults: preflightToken.userDefaults)

        guard runningExecutions[executionKey] == nil else { return .inProgress }

        runningExecutions[executionKey] = token.identifier
        return .started(token)
    }

    func isCurrent(_ token: SchedulingExecutionToken) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        return generations[token.environment, default: 0] == token.generation
    }

    func performStateAccessIfCurrent(_ token: SchedulingExecutionToken,
                                     action: () -> Void) -> Bool
    {
        lock.lock()
        defer { lock.unlock() }

        guard generations[token.environment, default: 0] == token.generation else { return false }
        action()
        return true
    }

    func finishExecution(_ token: SchedulingExecutionToken) {
        guard let executionKey = token.executionKey else { return }

        lock.lock()
        defer { lock.unlock() }

        guard runningExecutions[executionKey] == token.identifier else { return }
        runningExecutions.removeValue(forKey: executionKey)
    }

    func reset(for userDefaults: SUKUserDefaults, action: () -> Void) {
        lock.lock()
        defer { lock.unlock() }

        generations[userDefaults.env, default: 0] &+= 1
        runningExecutions = runningExecutions.filter { key, _ in
            key.environment != userDefaults.env
        }
        action()
    }

    private func makeToken(userDefaults: SUKUserDefaults,
                           executionKey: SchedulingExecutionKey?) -> SchedulingExecutionToken
    {
        SchedulingExecutionToken(identifier: UUID(),
                                 environment: userDefaults.env,
                                 generation: generations[userDefaults.env, default: 0],
                                 executionKey: executionKey,
                                 userDefaults: userDefaults)
    }
}

private struct SchedulingExecutionKey: Hashable {
    let environment: SUKUserDefaults.Environment
    let storageKey: String
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
        shouldRun(in: currentContext)
    }

    func hasRecordedDate() -> Bool {
        stateStore.integer(for: currentContext) != 0
    }

    func recordCurrentDate() {
        if let token = SchedulingExecutionScope.currentToken {
            _ = recordCurrentDate(for: token)
        } else {
            recordCurrentDate(in: currentContext)
        }
    }

    func executionToken(in userDefaults: SUKUserDefaults) -> SchedulingExecutionToken {
        executionGate.token(for: userDefaults)
    }

    func beginExecution(in userDefaults: SUKUserDefaults,
                        preflightToken: SchedulingExecutionToken) -> SchedulingExecutionDecision
    {
        executionGate.beginExecution(for: context(for: userDefaults),
                                     preflightToken: preflightToken)
    }

    func recordCurrentDate(for token: SchedulingExecutionToken) -> Bool {
        executionGate.performStateAccessIfCurrent(token) {
            recordCurrentDate(in: context(for: token.userDefaults))
        }
    }

    func isCurrent(_ token: SchedulingExecutionToken) -> Bool {
        executionGate.isCurrent(token)
    }

    func performStateAccessIfCurrent(_ token: SchedulingExecutionToken,
                                     action: () -> Void) -> Bool
    {
        executionGate.performStateAccessIfCurrent(token, action: action)
    }

    func finishExecution(_ token: SchedulingExecutionToken) {
        executionGate.finishExecution(token)
    }

    private func shouldRun(in context: SchedulingStateContext) -> Bool {
        stateStore.integer(for: context) < clock.currentDate()
    }

    private func recordCurrentDate(in context: SchedulingStateContext) {
        let currentDate = clock.currentDate()
        guard stateStore.integer(for: context) < currentDate else { return }

        stateStore.set(currentDate, for: context)
    }

    private func context(for userDefaults: SUKUserDefaults) -> SchedulingStateContext {
        SchedulingStateContext(userDefaults: userDefaults, key: key)
    }

    private var currentContext: SchedulingStateContext {
        context(for: SchedulingExecutionScope.currentToken?.userDefaults
            ?? SUKUserDefaults.standard)
    }
}
