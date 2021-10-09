//
//  RequestReviewCondition.swift
//  SwiftyUpdateKit
//
//  Created by Masaki Ando on 2021/10/09.
//  Copyright © 2021 Hituzi Ando. All rights reserved.
//

import Foundation

/// The key of UserDefaults.standard.
/// The value retrieved with this key is Int value as yyyyMMdd representation.
public let SwiftyUpdateKitLastRequireReviewDateKey = "jp.hituzi.SwiftyUpdateKit.lastRequireReviewDateKey"

public protocol RequestReviewCondition: AnyObject {
    /// If returns true, requests the review of the app.
    func shouldRequestReview() -> Bool
}

/// Always asks a user for a review.
open class RequestReviewConditionAlways: RequestReviewCondition {

    public init() {
    }

    open func shouldRequestReview() -> Bool {
        true
    }
}

/// Does not ask a user for a review whenever.
open class RequestReviewConditionDisable: RequestReviewCondition {

    public init() {
    }

    open func shouldRequestReview() -> Bool {
        false
    }
}

/// Asks a user for a review one time by a day.
open class RequestReviewConditionDaily: RequestReviewCondition {

    public init() {
    }

    open func shouldRequestReview() -> Bool {
        let lastDate = UserDefaults.standard.integer(forKey: SwiftyUpdateKitLastRequireReviewDateKey)
        let today = Utility.currentDate()

        guard lastDate < today else { return false }

        let ud = UserDefaults.standard
        ud.set(today, forKey: SwiftyUpdateKitLastRequireReviewDateKey)
        ud.synchronize()

        return true
    }
}

/// Asks a user for a review one time by a day, but skips first day.
open class RequestReviewConditionDailySkipFirstDay: RequestReviewCondition {

    public init() {
    }

    open func shouldRequestReview() -> Bool {
        let lastDate = UserDefaults.standard.integer(forKey: SwiftyUpdateKitLastRequireReviewDateKey)

        // lastDate is 0 means the first day because the value is not set.
        if lastDate == 0 {
            let today = Utility.currentDate()
            let ud = UserDefaults.standard
            ud.set(today, forKey: SwiftyUpdateKitLastRequireReviewDateKey)
            ud.synchronize()

            return false
        }

        return RequestReviewConditionDaily().shouldRequestReview()
    }
}
