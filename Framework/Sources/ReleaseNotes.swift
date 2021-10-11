//
//  ReleaseNotes.swift
//  SwiftyUpdateKit
//
//  Created by Masaki Ando on 2021/10/09.
//  Copyright © 2021 Hituzi Ando. All rights reserved.
//

import Foundation

/// The key of UserDefaults.standard.
public let SwiftyUpdateKitReleaseNotesVersionKey = "jp.hituzi.SwiftyUpdateKit.ReleaseNotesVersionKey"

struct ReleaseNotes: Codable {
    /// Latest version of the release notes. Default value of this property is 0.
    let latest: Int
    /// A user ID.
    let userID: String

    static func first(forUserID userID: String) -> ReleaseNotes {
        let dict = dictionary()
        if let releaseNotes = dict[userID] {
            return releaseNotes
        }
        else {
            return ReleaseNotes(latest: 0, userID: userID)
        }
    }

    static func isLatest(_ releaseNotesVersion: Int, forUserID userID: String) -> Bool {
        first(forUserID: userID).latest >= releaseNotesVersion
    }

    static func update(_ releaseNotesVersion: Int, forUserID userID: String) {
        var dict = dictionary()
        let releaseNotes = ReleaseNotes(latest: releaseNotesVersion, userID: userID)
        dict[userID] = releaseNotes
        setDictionary(dict)
    }

    private static func dictionary() -> [String: ReleaseNotes] {
        if let string = UserDefaults.standard.string(forKey: SwiftyUpdateKitReleaseNotesVersionKey),
           let data = Data(base64Encoded: string),
           let dictionary = try? JSONDecoder().decode([String: ReleaseNotes].self, from: data) {
            return dictionary
        }
        else {
            return [:]
        }
    }

    private static func setDictionary(_ dictionary: [String: ReleaseNotes]) {
        if let data = try? JSONEncoder().encode(dictionary) {
            let string = data.base64EncodedString()
            let ud = UserDefaults.standard
            ud.set(string, forKey: SwiftyUpdateKitReleaseNotesVersionKey)
            ud.synchronize()
        }
    }
}
