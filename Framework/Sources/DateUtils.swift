//
//  DateUtils.swift
//  SwiftyUpdateKit
//
//  Created by Masaki Ando on 2021/10/08.
//  Copyright © 2023 Hituzi Ando. All rights reserved.
//

import Foundation

struct DateUtils {
    /// Returns current date as Int value as yyyyMMdd representation.
    ///
    /// - Parameter locale: Locale.
    /// - Returns: Current date as Int value as yyyyMMdd representation.
    static func currentDate(locale: Locale) -> Int {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = locale
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd"
        let str = formatter.string(from: Date())
        if let dateInt = Int(str) {
            return dateInt
        } else {
            // Unsupported locale.
            // print(locale.identifier)
            return currentDate()
        }
    }

    /// Returns current date as Int value as yyyyMMdd representation using "en_US_POSIX" locale.
    ///
    /// - Returns: Current date as Int value as yyyyMMdd representation.
    static func currentDate() -> Int {
        currentDate(locale: Locale(identifier: "en_US_POSIX"))
    }
}
