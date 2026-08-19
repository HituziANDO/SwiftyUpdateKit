//
//  RequestReviewCondition.swift
//  SwiftyUpdateKit
//
//  Created by Masaki Ando on 2021/10/09.
//  Copyright © 2021 Hituzi Ando. All rights reserved.
//

import Foundation

/// The key of UserDefaults.standard.
/// The value retrieved with this key is the last review request attempt date as an Int in yyyyMMdd
/// representation. Skip-first-day conditions initially store the first evaluation date.
public let SwiftyUpdateKitLastRequireReviewDateKey =
    "jp.hituzi.SwiftyUpdateKit.lastRequireReviewDateKey"

public protocol RequestReviewCondition: AnyObject {
    /// If returns true, requests the review of the app.
    func shouldRequestReview() -> Bool
}

/// Records a review request attempt for a condition that maintains scheduling state.
///
/// StoreKit does not report whether the system displayed the review interface, so the stored value
/// represents an attempt rather than a confirmed presentation.
public protocol ReviewRequestAttemptRecording: AnyObject {
    /// Records that the app called the StoreKit review request API.
    func recordReviewRequestAttempt()
}

/// Always asks a user for a review.
open class RequestReviewConditionAlways: RequestReviewCondition {
    public init() {}

    open func shouldRequestReview() -> Bool {
        true
    }
}

/// Does not ask a user for a review whenever.
open class RequestReviewConditionDisable: RequestReviewCondition {
    public init() {}

    open func shouldRequestReview() -> Bool {
        false
    }
}

/// Asks a user for a review once a day.
open class RequestReviewConditionDaily: RequestReviewCondition, ReviewRequestAttemptRecording {
    private var schedule = DailySchedule(clock: SystemSUKClock(),
                                         stateStore: UserDefaultsSchedulingStateStore(),
                                         key: SwiftyUpdateKitLastRequireReviewDateKey)

    public init() {}

    init(clock: SUKClock, stateStore: SUKSchedulingStateStore) {
        schedule = DailySchedule(clock: clock,
                                 stateStore: stateStore,
                                 key: SwiftyUpdateKitLastRequireReviewDateKey)
    }

    open func shouldRequestReview() -> Bool {
        schedule.shouldRun()
    }

    open func recordReviewRequestAttempt() {
        schedule.recordCurrentDate()
    }
}

/// Asks a user for a review once a day, but skips first day.
open class RequestReviewConditionDailySkipFirstDay: RequestReviewCondition,
    ReviewRequestAttemptRecording
{
    private var schedule = DailySchedule(clock: SystemSUKClock(),
                                         stateStore: UserDefaultsSchedulingStateStore(),
                                         key: SwiftyUpdateKitLastRequireReviewDateKey)

    public init() {}

    init(clock: SUKClock, stateStore: SUKSchedulingStateStore) {
        schedule = DailySchedule(clock: clock,
                                 stateStore: stateStore,
                                 key: SwiftyUpdateKitLastRequireReviewDateKey)
    }

    open func shouldRequestReview() -> Bool {
        if !schedule.hasRecordedDate() {
            schedule.recordCurrentDate()
            return false
        }

        return schedule.shouldRun()
    }

    open func recordReviewRequestAttempt() {
        schedule.recordCurrentDate()
    }
}

/// Asks a user for a review when the app is launched and once a day.
open class RequestReviewConditionLaunchingAndDaily: RequestReviewCondition,
    ReviewRequestAttemptRecording
{
    private var schedule = DailySchedule(clock: SystemSUKClock(),
                                         stateStore: InMemorySchedulingStateStore(),
                                         key: SwiftyUpdateKitLastRequireReviewDateKey)

    public init() {}

    init(clock: SUKClock, stateStore: SUKSchedulingStateStore) {
        schedule = DailySchedule(clock: clock,
                                 stateStore: stateStore,
                                 key: SwiftyUpdateKitLastRequireReviewDateKey)
    }

    open func shouldRequestReview() -> Bool {
        schedule.shouldRun()
    }

    open func recordReviewRequestAttempt() {
        schedule.recordCurrentDate()
    }
}

/// Asks a user for a review when the app is launched and once a day, but skips first day.
open class RequestReviewConditionLaunchingAndDailySkipFirstDay: RequestReviewCondition,
    ReviewRequestAttemptRecording
{
    private var schedule = DailySchedule(clock: SystemSUKClock(),
                                         stateStore: InMemorySchedulingStateStore(),
                                         key: SwiftyUpdateKitLastRequireReviewDateKey)

    public init() {}

    init(clock: SUKClock, stateStore: SUKSchedulingStateStore) {
        schedule = DailySchedule(clock: clock,
                                 stateStore: stateStore,
                                 key: SwiftyUpdateKitLastRequireReviewDateKey)
    }

    open func shouldRequestReview() -> Bool {
        if !schedule.hasRecordedDate() {
            schedule.recordCurrentDate()
            return false
        }

        return schedule.shouldRun()
    }

    open func recordReviewRequestAttempt() {
        schedule.recordCurrentDate()
    }
}
