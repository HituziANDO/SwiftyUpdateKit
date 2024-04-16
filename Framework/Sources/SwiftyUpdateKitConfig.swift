//
//  SwiftyUpdateKitConfig.swift
//  SwiftyUpdateKit
//
//  Created by Masaki Ando on 2021/10/08.
//  Copyright © 2021 Hituzi Ando. All rights reserved.
//

import Foundation

public struct SwiftyUpdateKitConfig {
    public static let defaultUpdateAlertTitle = "Released new version!"
    public static let defaultUpdateAlertMessage =
        "Please update the app. Please refer to the App Store for details of the update contents."
    public static let defaultUpdateButtonTitle = "Update"
    public static let defaultRemindMeLaterButtonTitle = "Remind me later"

    /// Current app version. Maybe specify following code.
    ///
    /// ```
    /// Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    /// ```
    public let version: String
    /// iTunes ID.
    /// e.g.) The App Store URL: "https://apps.apple.com/app/sampleapp/id1234567890" -> iTunesID is
    /// 1234567890
    public let iTunesID: String
    /// The App Store URL of your app.
    public let storeURL: String
    /// The country code used by iTunes Search API. For example: "jp".
    /// See http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2 for a list of ISO Country Codes.
    public let country: String?
    /// The method to compare the app version.
    public let versionCompare: VersionComparable
    /// The update alert's title.
    public let updateAlertTitle: String
    /// The update alert's message.
    public let updateAlertMessage: String
    /// The update button's label.
    public let updateButtonTitle: String
    /// The remind-me-later button's label. If nil is specified, the button is hidden.
    /// That is, you can force a user to update because it cannot be canceled.
    public let remindMeLaterButtonTitle: String?
    /// The count of retry when iTunes Search API failed. Default value is 2.
    public let retryCount: Int
    /// Retries iTunes Search API after this delay in seconds. Default value is 1 second.
    public let retryDelay: TimeInterval
    /// Tells whether the database is in development environment.
    public let isDevelopment: Bool

    /// Initializes the configuration.
    ///
    /// - Parameters:
    ///   - version:
    ///   - iTunesID:
    ///   - storeURL:
    ///   - country:
    ///   - versionCompare:
    ///   - updateAlertTitle:
    ///   - updateAlertMessage:
    ///   - updateButtonTitle:
    ///   - remindMeLaterButtonTitle:
    ///   - retryCount:
    ///   - retryDelay:
    ///   - development: If true, the database is in development environment. Otherwise it is for
    /// production environment.
    /// Must set false when release your app.
    public init(version: String,
                iTunesID: String,
                storeURL: String,
                country: String? = nil,
                versionCompare: VersionComparable? = nil,
                updateAlertTitle: String = SwiftyUpdateKitConfig.defaultUpdateAlertTitle,
                updateAlertMessage: String = SwiftyUpdateKitConfig.defaultUpdateAlertMessage,
                updateButtonTitle: String = SwiftyUpdateKitConfig.defaultUpdateButtonTitle,
                remindMeLaterButtonTitle: String? = SwiftyUpdateKitConfig
                    .defaultRemindMeLaterButtonTitle,
                retryCount: Int = 2,
                retryDelay: TimeInterval = 1,
                development: Bool = false)
    {
        self.version = version
        self.iTunesID = iTunesID
        self.storeURL = storeURL
        self.country = country
        self.versionCompare = versionCompare ?? VersionCompare()
        self.updateAlertTitle = updateAlertTitle.isEmpty ? SwiftyUpdateKitConfig
            .defaultUpdateAlertTitle : updateAlertTitle
        self.updateAlertMessage = updateAlertMessage.isEmpty ? SwiftyUpdateKitConfig
            .defaultUpdateAlertMessage : updateAlertMessage
        self.updateButtonTitle = updateButtonTitle.isEmpty ? SwiftyUpdateKitConfig
            .defaultUpdateButtonTitle : updateButtonTitle
        self.remindMeLaterButtonTitle = remindMeLaterButtonTitle
        self.retryCount = retryCount
        self.retryDelay = retryDelay
        isDevelopment = development
    }
}
