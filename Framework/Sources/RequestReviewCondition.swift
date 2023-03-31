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
        let lastDate = SUKUserDefaults.standard.integer(forKey: SwiftyUpdateKitLastRequireReviewDateKey)
        let today = DateUtils.currentDate()

        guard lastDate < today else { return false }

        SUKUserDefaults.standard.set(today, forKey: SwiftyUpdateKitLastRequireReviewDateKey)

        return true
    }
}

/// Asks a user for a review one time by a day, but skips first day.
open class RequestReviewConditionDailySkipFirstDay: RequestReviewCondition {

    public init() {
    }

    open func shouldRequestReview() -> Bool {
        let lastDate = SUKUserDefaults.standard.integer(forKey: SwiftyUpdateKitLastRequireReviewDateKey)

        // lastDate is 0 means the first day because the value is not set.
        if lastDate == 0 {
            let today = DateUtils.currentDate()
            SUKUserDefaults.standard.set(today, forKey: SwiftyUpdateKitLastRequireReviewDateKey)

            return false
        }

        return RequestReviewConditionDaily().shouldRequestReview()
    }
}
