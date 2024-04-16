//
//  ReleaseNotes.swift
//  SwiftyUpdateKit
//
//  Created by Masaki Ando on 2021/10/09.
//  Copyright © 2021 Hituzi Ando. All rights reserved.
//

import Foundation

/// The key of UserDefaults.standard.
public let SwiftyUpdateKitLatestAppVersionKey = "jp.hituzi.SwiftyUpdateKit.LatestAppVersionKey"

struct ReleaseNotes: Codable {
    /// Latest app version. Default value of this property is nil.
    let latest: String?
    /// A user ID.
    let userID: String

    static func first(forUserID userID: String) -> ReleaseNotes {
        let dict = dictionary()
        if let releaseNotes = dict[userID] {
            return releaseNotes
        } else {
            return ReleaseNotes(latest: nil, userID: userID)
        }
    }

    static func update(_ appVersion: String, forUserID userID: String) {
        var dict = dictionary()
        let releaseNotes = ReleaseNotes(latest: appVersion, userID: userID)
        dict[userID] = releaseNotes
        setDictionary(dict)
    }

    private static func dictionary() -> [String: ReleaseNotes] {
        if let string = SUKUserDefaults.standard.string(forKey: SwiftyUpdateKitLatestAppVersionKey),
           let data = Data(base64Encoded: string),
           let dictionary = try? JSONDecoder().decode([String: ReleaseNotes].self, from: data)
        {
            return dictionary
        } else {
            return [:]
        }
    }

    private static func setDictionary(_ dictionary: [String: ReleaseNotes]) {
        if let data = try? JSONEncoder().encode(dictionary) {
            let string = data.base64EncodedString()
            SUKUserDefaults.standard.set(string, forKey: SwiftyUpdateKitLatestAppVersionKey)
        }
    }
}
