//
//  VersionCompare.swift
//  SwiftyUpdateKit
//
//  Created by Masaki Ando on 2021/10/08.
//  Copyright © 2021 Hituzi Ando. All rights reserved.
//

import Foundation

public protocol VersionComparable {
    /// The compare method.
    ///
    /// - Parameters:
    ///   - storeVersion: The version of the app released on App Store.
    ///   - currentVersion: Current version of the app.
    /// - Returns: true if storeVersion > currentVersion.
    func compare(_ storeVersion: String, with currentVersion: String) -> Bool
}

public class VersionCompare: VersionComparable {

    public init() {
    }

    public func compare(_ storeVersion: String, with currentVersion: String) -> Bool {
        let storeVerInt = versionToInt(storeVersion)
        let currentVerInt = versionToInt(currentVersion)
        let isOld = storeVerInt > currentVerInt
        return isOld
    }

    /// Converts the version to Int type.
    ///
    /// - Parameter ver: major.minor.patch. minor: [0,999], patch: [0,99999999]
    /// - Returns: Int value.
    private func versionToInt(_ ver: String) -> Int64 {
        let arr = ver.split(separator: ".").map { Int64($0) ?? 0 }

        switch arr.count {
            case 3:
                return arr[0] * 1000 * 100_000_000 + arr[1] * 100_000_000 + arr[2]
            case 2:
                return arr[0] * 1000 * 100_000_000 + arr[1] * 100_000_000
            case 1:
                return arr[0] * 1000 * 100_000_000
            default:
                assertionFailure("Illegal version string.")
                return 0
        }
    }
}
