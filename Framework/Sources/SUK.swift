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

/// SwiftyUpdateKit.
public class SUK {
    /// SwiftyUpdateKit version.
    public static let version = "0.1.2"

    private static var config: SwiftyUpdateKitConfig?
    private static var log: Log?

    /// Initializes SwiftyUpdateKit.
    ///
    /// - Parameters:
    ///   - config: A configuration.
    ///   - log: The closure outputs logs.
    public static func applicationDidFinishLaunching(withConfig config: SwiftyUpdateKitConfig,
                                                     log: Log? = nil) {
        self.config = config
        self.log = log
    }

    /// If specified condition returns true, this method checks the app version whether new version is released.
    /// And when new app version is installed, this method can show the release notes to a user.
    ///
    /// - Parameters:
    ///   - condition: If the condition returns true, checks the app version.
    ///   - update: The closure is called when current app version is old. If nil is specified, default alert is shown.
    ///   - newRelease: The closure is called when new app version is installed.
    ///   - userID: A user's ID to show the release notes when new app version is installed. Default value of this argument is "SwiftyUpdateKitUser".
    ///   - noop: The closure is called when no operation.
    public static func checkVersion(_ condition: CheckVersionCondition,
                                    update: ((_ newVersion: String?, _ releaseNotes: String?) -> ())? = nil,
                                    newRelease: ((_ newVersion: String?, _ releaseNotes: String?) -> ())? = nil,
                                    forUserID userID: String = "SwiftyUpdateKitUser",
                                    noop: (() -> ())? = nil) {
        checkVersion(condition, update: update) {
            guard let config = config else { return }

            guard !ReleaseNotes.isLatest(config.releaseNotesVersion, forUserID: userID) else {
                logf("Saved version of the release notes is already latest.", log)
                noop?()
                return
            }

            guard let newRelease = newRelease else {
                noop?()
                return
            }

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

                        ReleaseNotes.update(config.releaseNotesVersion, forUserID: userID)

                        DispatchQueue.main.async {
                            newRelease(lookUpResult.version, lookUpResult.releaseNotes)
                        }
                }
            }
        }
    }

    /// Opens App Store.
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

    /// Shows the release notes to a user when new app version is installed.
    ///
    /// - Parameters:
    ///   - rootViewController: A parent view controller presents this view controller.
    ///   - text: Release notes.
    ///   - title: A title. Default value of this argument is "Release Notes".
    ///   - version: new app version.
    ///   - windowSize: A window size. Default value of this argument is (480, 320). This value is used on macOS only.
    public static func showReleaseNotes(from rootViewController: SUKViewController,
                                        text: String?,
                                        title: String = "Release Notes",
                                        version: String? = nil,
                                        windowSize: CGSize = CGSize(width: 480, height: 320)) {
        #if os(OSX)
        let viewController = ReleaseNotesController(windowSize: windowSize,
                                                    title: title,
                                                    text: text ?? "",
                                                    version: version)
        rootViewController.presentAsModalWindow(viewController)
        #elseif os(iOS)
        let viewController = ReleaseNotesController(title: title,
                                                    text: text ?? "",
                                                    version: version)
        viewController.modalTransitionStyle = .coverVertical
        viewController.modalPresentationStyle = .automatic
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

    /// Resets the status.
    /// For example, you may use this method during testing and development.
    public static func reset() {
        let ud = UserDefaults.standard
        ud.set(nil, forKey: SwiftyUpdateKitLastCheckVersionDateKey)
        ud.set(nil, forKey: SwiftyUpdateKitLastRequireReviewDateKey)
        ud.set(nil, forKey: SwiftyUpdateKitReleaseNotesVersionKey)
        ud.synchronize()
    }
}

private extension SUK {

    static func checkVersion(_ condition: CheckVersionCondition,
                             update: ((_ newVersion: String?, _ releaseNotes: String?) -> ())?,
                             noop: @escaping () -> ()) {
        DispatchQueue.main.async {
            guard let config = config else {
                logf("`applicationDidFinishLaunching(withConfig:)` method is not called yet.", log)
                return
            }

            guard condition.shouldCheckVersion() else {
                logf("Skips the version check.", log)
                DispatchQueue.main.async {
                    noop()
                }
                return
            }

            ITunesSearchAPI.lookUp(with: config) { result in
                switch result {
                    case .failure(let error):
                        // Ignore an error.
                        logf(error.localizedDescription, log)
                        DispatchQueue.main.async {
                            noop()
                        }
                    case .success(let lookUpResults):
                        logf(lookUpResults.description, log)
                        guard let lookUpResult = lookUpResults.first,
                              let storeVersion = lookUpResult.version else {
                            // Ignore an error.
                            logf("version does not exist in the response data.", log)
                            DispatchQueue.main.async {
                                noop()
                            }
                            return
                        }

                        let isOld = config.versionCompare.compare(storeVersion, with: config.version)

                        if isOld {
                            logf("This app version is old.", log)
                            if update == nil {
                                DispatchQueue.main.async {
                                    let alert = Alert(title: config.updateAlertTitle,
                                                      message: config.updateAlertMessage)
                                        .addAction(config.updateButtonTitle) {
                                            Self.openAppStore()
                                        }
                                    if let title = config.remindMeLaterButtonTitle, !title.isEmpty {
                                        alert.addAction(title)
                                    }
                                    alert.showAsModal()
                                }
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
                                noop()
                            }
                        }
                }
            }
        }
    }
}
