//
//  VersionCheckCondition.swift
//  SwiftyUpdateKit
//
//  Created by Masaki Ando on 2021/10/08.
//  Copyright © 2021 Hituzi Ando. All rights reserved.
//

import Foundation

/// The key of UserDefaults.standard.
/// The value retrieved with this key is the last successful check date as an Int in yyyyMMdd
/// representation.
public let SwiftyUpdateKitLastVersionCheckDateKey =
    "jp.hituzi.SwiftyUpdateKit.lastVersionCheckDateKey"

public protocol VersionCheckCondition: AnyObject {
    /// If returns true, checks the app version.
    func shouldCheckVersion() -> Bool
}

/// Records a successful version check for a condition that maintains scheduling state.
public protocol VersionCheckSuccessRecording: AnyObject {
    /// Records that the App Store returned a valid version for the current app.
    func recordSuccessfulVersionCheck()
}

/// Always checks the app version.
open class VersionCheckConditionAlways: VersionCheckCondition {
    public init() {}

    open func shouldCheckVersion() -> Bool {
        true
    }
}

/// Does not check the app version whenever.
open class VersionCheckConditionDisable: VersionCheckCondition {
    public init() {}

    open func shouldCheckVersion() -> Bool {
        false
    }
}

/// Checks the app version once a day.
open class VersionCheckConditionDaily: VersionCheckCondition, VersionCheckSuccessRecording {
    private var schedule = DailySchedule(clock: SystemSUKClock(),
                                         stateStore: UserDefaultsSchedulingStateStore(),
                                         key: SwiftyUpdateKitLastVersionCheckDateKey)

    public init() {}

    init(clock: SUKClock, stateStore: SUKSchedulingStateStore) {
        schedule = DailySchedule(clock: clock,
                                 stateStore: stateStore,
                                 key: SwiftyUpdateKitLastVersionCheckDateKey)
    }

    open func shouldCheckVersion() -> Bool {
        schedule.shouldRun()
    }

    open func recordSuccessfulVersionCheck() {
        schedule.recordCurrentDate()
    }
}

/// Checks the app version when the app is launched and once a day.
open class VersionCheckConditionLaunchingAndDaily: VersionCheckCondition,
    VersionCheckSuccessRecording
{
    private var schedule = DailySchedule(clock: SystemSUKClock(),
                                         stateStore: InMemorySchedulingStateStore(),
                                         key: SwiftyUpdateKitLastVersionCheckDateKey)

    public init() {}

    init(clock: SUKClock, stateStore: SUKSchedulingStateStore) {
        schedule = DailySchedule(clock: clock,
                                 stateStore: stateStore,
                                 key: SwiftyUpdateKitLastVersionCheckDateKey)
    }

    open func shouldCheckVersion() -> Bool {
        schedule.shouldRun()
    }

    open func recordSuccessfulVersionCheck() {
        schedule.recordCurrentDate()
    }
}
