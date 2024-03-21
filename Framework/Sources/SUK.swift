//
//  SUK.swift
//  SwiftyUpdateKit
//
//  Created by Masaki Ando on 2021/10/08.
//  Copyright © 2021 Hituzi Ando. All rights reserved.
//

import Foundation
import StoreKit

#if os(OSX)
public typealias SUKViewController = NSViewController
#elseif os(iOS)
public typealias SUKViewController = UIViewController
#endif

/// The closure is called when new app version is released on the App Store.
public typealias UpdateHandler = (_ newVersion: String?, _ releaseNotes: String?) -> ()

/// The closure is called when new app version is installed.
/// If a user has updated or installed firstly since the introduction of SwiftyUpdateKit, `firstUpdated` flag is true, otherwise false.
public typealias NewReleaseHandler = (_ newVersion: String?, _ releaseNotes: String?, _ firstUpdated: Bool) -> ()

/// SwiftyUpdateKit.
public class SUK {
    /// SwiftyUpdateKit version.
    public static let version = "1.3.1"

    private static var config: SwiftyUpdateKitConfig?
    private static var log: Log?

    /// Initializes SwiftyUpdateKit.
    ///
    /// - Parameters:
    ///   - config: A configuration.
    ///   - log: The closure outputs logs.
    public static func initialize(withConfig config: SwiftyUpdateKitConfig,
                                  log: Log? = nil) {
        self.config = config
        self.log = log
    }

    /// Initializes SwiftyUpdateKit.
    ///
    /// - Parameters:
    ///   - config: A configuration.
    ///   - log: The closure outputs logs.
    @available(*, deprecated, renamed: "initialize(withConfig:log:)")
    @inlinable
    public static func applicationDidFinishLaunching(withConfig config: SwiftyUpdateKitConfig,
                                                     log: Log? = nil) {
        initialize(withConfig: config, log: log)
    }

    /// If specified condition returns true, this method checks the app version whether new version is released.
    /// And when new app version is installed, this method can show the release notes to a user.
    ///
    /// - Parameters:
    ///   - condition: If the condition returns true, checks the app version.
    ///   - update: The closure is called when current app version is old. If nil is specified, default alert is shown.
    ///   - newRelease: The closure is called when new app version is installed. If nil is specified, to show the release notes to a user is ignored.
    ///   - userID: A user's ID to show the release notes when new app version is installed. Default value of this argument is "SwiftyUpdateKitUser".
    ///   - noop: The closure is called when no operation.
    public static func checkVersion(_ condition: VersionCheckCondition,
                                    update: UpdateHandler? = nil,
                                    newRelease: NewReleaseHandler? = nil,
                                    forUserID userID: String = "SwiftyUpdateKitUser",
                                    noop: (() -> ())? = nil) {
        checkVersion(condition, update: update) { lookUpResult in
            guard let newRelease = newRelease else {
                // Not need to show the new release.
                noop?()
                return
            }

            if let result = lookUpResult {
                // Use fetched lookUpResult.
                checkNewRelease(result, newRelease: newRelease, forUserID: userID, noop: noop)
            }
            else {
                guard let config = config else { return }

                ITunesSearchAPI.lookUp(with: config) { result in
                    switch result {
                        case .failure(let error):
                            // Ignore an error.
                            logf(error.localizedDescription, log)
                            DispatchQueue.main.async {
                                noop?()
                            }
                        case .success(let lookUpResults):
                            guard let lookUpResult = lookUpResults.first else {
                                // Ignore an error.
                                logf("lookUpResult does not exist in the response data.", log)
                                DispatchQueue.main.async {
                                    noop?()
                                }
                                return
                            }

                            checkNewRelease(lookUpResult,
                                            newRelease: newRelease,
                                            forUserID: userID,
                                            noop: noop)
                    }
                }
            }
        }
    }

    /// Opens the App Store.
    public static func openAppStore() {
        DispatchQueue.main.async {
            guard let config = config else {
                logf("`applicationDidFinishLaunching(withConfig:)` method is not called yet.", log)
                return
            }

            let url = URL(string: config.storeURL)!
            logf(url.absoluteString, log)
            #if os(OSX)
            NSWorkspace.shared.open(url)
            #elseif os(iOS)
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            #endif
        }
    }

    /// Shows the update alert for a user to install new app version.
    public static func showUpdateAlert() {
        DispatchQueue.main.async {
            guard let config = config else {
                logf("`applicationDidFinishLaunching(withConfig:)` method is not called yet.", log)
                return
            }

            let alert = Alert(title: config.updateAlertTitle,
                              message: config.updateAlertMessage)
                    .addAction(config.updateButtonTitle) { Self.openAppStore() }

            if let title = config.remindMeLaterButtonTitle, !title.isEmpty {
                alert.addAction(title)
            }

            alert.showAsModal()
        }
    }

    /// Shows the release notes to a user when new app version is installed.
    ///
    /// - Parameters:
    ///   - rootViewController: A parent view controller presents this view controller.
    ///   - text: Release notes.
    ///   - title: A title. Default value of this argument is "Release Notes".
    ///   - version: new app version.
    ///   - windowSize: A window size. Default value of this argument is (480, 320). This value is used on macOS only.
    ///   - dismissHandler: A handler called when the release notes has been disappeared.
    public static func showReleaseNotes(from rootViewController: SUKViewController,
                                        text: String?,
                                        title: String = "Release Notes",
                                        version: String? = nil,
                                        windowSize: CGSize = CGSize(width: 480, height: 320),
                                        dismissHandler: (() -> ())? = nil) {
        #if os(OSX)
        let viewController = ReleaseNotesController(windowSize: windowSize,
                                                    title: title,
                                                    text: text ?? "",
                                                    version: version)
        viewController.dismissHandler = dismissHandler
        rootViewController.presentAsModalWindow(viewController)
        #elseif os(iOS)
        let viewController = ReleaseNotesController(title: title,
                                                    text: text ?? "",
                                                    version: version)
        viewController.modalTransitionStyle = .coverVertical
        viewController.modalPresentationStyle = .automatic
        viewController.dismissHandler = dismissHandler
        rootViewController.present(viewController, animated: true)
        #endif
    }

    /// Asks a user for a review of the app if specified condition returns true.
    public static func requestReview(_ condition: RequestReviewCondition) {
        DispatchQueue.main.async {
            if condition.shouldRequestReview() {
                SKStoreReviewController.requestReview()
            }
        }
    }

    /// Resets the status: stored date of version check condition, stored date of request review condition,
    /// and stored app version for the release notes.
    /// For example, you may use this method during testing and development.
    public static func reset() {
        let ud = SUKUserDefaults.standard
        ud.removeObject(forKey: SwiftyUpdateKitLastVersionCheckDateKey)
        ud.removeObject(forKey: SwiftyUpdateKitLastRequireReviewDateKey)
        ud.removeObject(forKey: SwiftyUpdateKitLatestAppVersionKey)
    }
}

private extension SUK {

    static func checkVersion(_ condition: VersionCheckCondition,
                             update: UpdateHandler?,
                             next: @escaping (LookUpResult?) -> ()) {
        DispatchQueue.main.async {
            guard let config = config else {
                logf("`applicationDidFinishLaunching(withConfig:)` method is not called yet.", log)
                return
            }

            guard condition.shouldCheckVersion() else {
                logf("Skips the version check.", log)
                DispatchQueue.main.async {
                    next(nil)
                }
                return
            }

            ITunesSearchAPI.lookUp(with: config) { result in
                switch result {
                    case .failure(let error):
                        // Ignore an error.
                        logf(error.localizedDescription, log)
                    case .success(let lookUpResults):
                        logf(lookUpResults.description, log)
                        guard let lookUpResult = lookUpResults.first,
                              let storeVersion = lookUpResult.version
                        else {
                            // Ignore an error.
                            logf("version does not exist in the response data.", log)
                            return
                        }

                        let isOld = config.versionCompare.compare(storeVersion, with: config.version)

                        if isOld {
                            logf("This app version is old.", log)
                            if update == nil {
                                // Use default update alert.
                                Self.showUpdateAlert()
                            }
                            else {
                                DispatchQueue.main.async {
                                    update?(lookUpResult.version, lookUpResult.releaseNotes)
                                }
                            }
                        }
                        else {
                            // Latest
                            logf("This app version is already latest.", log)
                            DispatchQueue.main.async {
                                next(lookUpResult)
                            }
                        }
                }
            }
        }
    }

    static func checkNewRelease(_ lookUpResult: LookUpResult,
                                newRelease: @escaping NewReleaseHandler,
                                forUserID userID: String,
                                noop: (() -> ())?) {
        guard let config = config else { return }

        guard let storeVersion = lookUpResult.version else {
            logf("version does not exist in the response data.", log)
            return
        }

        guard storeVersion == config.version else {
            logf("Current app version is not equal to the version released on the App Store.", log)
            DispatchQueue.main.async {
                noop?()
            }
            return
        }

        guard let savedVersion = ReleaseNotes.first(forUserID: userID).latest else {
            // First updated.
            logf("A user has installed the app firstly.", log)
            ReleaseNotes.update(storeVersion, forUserID: userID)

            DispatchQueue.main.async {
                newRelease(storeVersion, lookUpResult.releaseNotes, true)
            }
            return
        }

        guard config.versionCompare.compare(storeVersion, with: savedVersion) else {
            logf("Saved app version is already latest.", log)
            DispatchQueue.main.async {
                noop?()
            }
            return
        }

        ReleaseNotes.update(storeVersion, forUserID: userID)

        DispatchQueue.main.async {
            newRelease(storeVersion, lookUpResult.releaseNotes, false)
        }
    }
}
