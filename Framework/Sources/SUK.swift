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
public typealias UpdateHandler = (_ newVersion: String?, _ releaseNotes: String?) -> Void

/// The closure is called when new app version is installed.
/// If a user has updated or installed firstly since the introduction of SwiftyUpdateKit,
/// `firstUpdated` flag is true, otherwise false.
public typealias NewReleaseHandler = (_ newVersion: String?, _ releaseNotes: String?,
                                      _ firstUpdated: Bool) -> Void

typealias SUKUpdateAlertPresenter = (_ config: SwiftyUpdateKitConfig,
                                     _ updateAction: @escaping () -> Void) -> Void
typealias SUKAppStoreURLOpener = (_ url: URL) -> Void

private struct VersionCheckOperationContext {
    let config: SwiftyUpdateKitConfig
    let logger: Log?
    let userDefaults: SUKUserDefaults
    let token: SchedulingExecutionToken
    let executionController: VersionCheckExecutionControlling?

    func recordSuccessfulVersionCheck(_ condition: VersionCheckCondition) -> Bool {
        guard isCurrent() else { return false }

        if let recordingCondition = condition as? VersionCheckSuccessRecording {
            SchedulingExecutionScope.withToken(token) {
                recordingCondition.recordSuccessfulVersionCheck()
            }
        }

        return isCurrent()
    }

    func isCurrent() -> Bool {
        if let executionController {
            return executionController.isCurrentVersionCheck(token)
        }

        return sharedSchedulingExecutionGate.isCurrent(token)
    }

    func performStateAccessIfCurrent(_ action: () -> Void) -> Bool {
        if let executionController {
            return executionController.performVersionCheckStateAccessIfCurrent(token,
                                                                               action: action)
        }

        return sharedSchedulingExecutionGate.performStateAccessIfCurrent(token, action: action)
    }

    func finish() {
        executionController?.finishVersionCheck(token)
    }

    func writeLog(_ message: String) {
        logf(message, logger)
    }
}

private struct ReviewRequestOperationContext {
    let token: SchedulingExecutionToken
    let executionController: ReviewRequestExecutionControlling?

    func isCurrent() -> Bool {
        if let executionController {
            return executionController.isCurrentReviewRequest(token)
        }

        return sharedSchedulingExecutionGate.isCurrent(token)
    }

    func finish() {
        executionController?.finishReviewRequest(token)
    }
}

/// SwiftyUpdateKit.
public class SUK {
    /// SwiftyUpdateKit version.
    public static let version = "1.5.0"

    private static let versionCheckInvalidatedLog =
        "Cancels the version check because its scheduling context was invalidated."

    /// Initializes SwiftyUpdateKit.
    /// Operations that are already queued or in progress keep the configuration and environment
    /// captured when they started. Call `reset()` before reinitializing to invalidate them.
    ///
    /// - Parameters:
    ///   - config: A configuration.
    ///   - log: The closure outputs logs.
    public static func initialize(withConfig config: SwiftyUpdateKitConfig,
                                  log: Log? = nil)
    {
        sharedSUKRuntimeState.initialize(config: config, log: log)
    }

    /// Initializes SwiftyUpdateKit.
    ///
    /// - Parameters:
    ///   - config: A configuration.
    ///   - log: The closure outputs logs.
    @available(*, deprecated, renamed: "initialize(withConfig:log:)")
    @inlinable
    public static func applicationDidFinishLaunching(withConfig config: SwiftyUpdateKitConfig,
                                                     log: Log? = nil)
    {
        initialize(withConfig: config, log: log)
    }

    /// If specified condition returns true, this method checks the app version whether new version
    /// is released.
    /// And when new app version is installed, this method can show the release notes to a user.
    ///
    /// - Parameters:
    ///   - condition: If the condition returns true, checks the app version.
    ///   - update: The closure is called when current app version is old. If nil is specified,
    /// default alert is shown.
    ///   - newRelease: The closure is called when new app version is installed. If nil is
    /// specified, to show the release notes to a user is ignored.
    ///   - userID: A user's ID to show the release notes when new app version is installed. Default
    /// value of this argument is "SwiftyUpdateKitUser".
    ///   - noop: The closure is called when no operation.
    public static func checkVersion(_ condition: VersionCheckCondition,
                                    update: UpdateHandler? = nil,
                                    newRelease: NewReleaseHandler? = nil,
                                    forUserID userID: String = "SwiftyUpdateKitUser",
                                    noop: (() -> Void)? = nil)
    {
        checkVersion(condition,
                     update: update,
                     newRelease: newRelease,
                     forUserID: userID,
                     noop: noop,
                     lookup: ITunesAppStoreLookup())
    }

    /// Opens the App Store.
    public static func openAppStore() {
        DispatchQueue.main.async {
            let runtimeContext = sharedSUKRuntimeState.snapshot()
            guard let config = runtimeContext.config else {
                logf("`applicationDidFinishLaunching(withConfig:)` method is not called yet.",
                     runtimeContext.log)
                return
            }

            let url = URL(string: config.storeURL)!
            logf(url.absoluteString, runtimeContext.log)
            openAppStoreURL(url)
        }
    }

    /// Shows the update alert for a user to install new app version.
    /// The alert and its update action use the configuration captured when this method is called.
    public static func showUpdateAlert() {
        let runtimeContext = sharedSUKRuntimeState.snapshot()

        DispatchQueue.main.async {
            guard let config = runtimeContext.config else {
                logf("`applicationDidFinishLaunching(withConfig:)` method is not called yet.",
                     runtimeContext.log)
                return
            }

            presentUpdateAlert(config) {
                let url = URL(string: config.storeURL)!
                logf(url.absoluteString, runtimeContext.log)
                openAppStoreURL(url)
            }
        }
    }

    static func enqueueUpdateAlert(config: SwiftyUpdateKitConfig,
                                   log: Log?,
                                   isCurrent: @escaping () -> Bool,
                                   presenter: @escaping SUKUpdateAlertPresenter,
                                   openURL: @escaping SUKAppStoreURLOpener)
    {
        DispatchQueue.main.async {
            guard isCurrent() else { return }

            presenter(config) {
                let url = URL(string: config.storeURL)!
                logf(url.absoluteString, log)
                openURL(url)
            }
        }
    }

    private static func presentUpdateAlert(_ config: SwiftyUpdateKitConfig,
                                           updateAction: @escaping () -> Void)
    {
        let alert = Alert(title: config.updateAlertTitle,
                          message: config.updateAlertMessage)
            .addAction(config.updateButtonTitle, handler: updateAction)

        if let title = config.remindMeLaterButtonTitle, !title.isEmpty {
            alert.addAction(title)
        }

        alert.showAsModal()
    }

    private static func openAppStoreURL(_ url: URL) {
        #if os(OSX)
        NSWorkspace.shared.open(url)
        #elseif os(iOS)
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        #endif
    }

    /// Shows the release notes to a user when new app version is installed.
    ///
    /// - Parameters:
    ///   - rootViewController: A parent view controller presents this view controller.
    ///   - text: Release notes.
    ///   - title: A title. Default value of this argument is "Release Notes".
    ///   - version: new app version.
    ///   - windowSize: A window size. Default value of this argument is (480, 320). This value is
    /// used on macOS only.
    ///   - dismissHandler: A handler called when the release notes has been disappeared.
    public static func showReleaseNotes(from rootViewController: SUKViewController,
                                        text: String?,
                                        title: String = "Release Notes",
                                        version: String? = nil,
                                        windowSize: CGSize = CGSize(width: 480, height: 320),
                                        dismissHandler: (() -> Void)? = nil)
    {
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

    /// Asks a user for the review of the app if specified condition returns true.
    ///
    /// - Parameter condition: The condition to request the review.
    @available(iOS, deprecated: 16.0, message: "Use `requestReview(_:, in:)` instead.")
    @available(macOS, deprecated: 13.0, message: "Use `requestReview(_:, in:)` instead.")
    public static func requestReview(_ condition: RequestReviewCondition) {
        enqueueReviewRequest(condition) {
            SKStoreReviewController.requestReview()
        }
    }

    #if os(OSX)
    /// Asks a user for the review of the app if specified condition returns true.
    ///
    /// https://developer.apple.com/documentation/storekit/appstore/requestreview(in:)-4r0y9#Discussion
    ///
    /// - Parameters:
    ///  - condition: The condition to request the review.
    ///  - controller: The controller that StoreKit uses to present the rating and review request
    /// interface.
    @available(macOS 13.0, *)
    public static func requestReview(_ condition: RequestReviewCondition,
                                     in controller: NSViewController)
    {
        enqueueReviewRequest(condition) {
            AppStore.requestReview(in: controller)
        }
    }
    #endif

    #if os(iOS)
    /// Asks a user for the review of the app if specified condition returns true.
    ///
    /// https://developer.apple.com/documentation/storekit/appstore/requestreview(in:)-1q8qs#Discussion
    ///
    /// - Parameters:
    ///   - condition: The condition to request the review.
    ///   - scene: The window scene that StoreKit uses to present the rating and review request
    /// interface.
    @available(iOS 16.0, *)
    public static func requestReview(_ condition: RequestReviewCondition, in scene: UIWindowScene) {
        enqueueReviewRequest(condition) {
            AppStore.requestReview(in: scene)
        }
    }

    /// Asks a user for the review of the app if specified condition returns true.
    ///
    /// https://developer.apple.com/documentation/storekit/appstore/requestreview(in:)-1q8qs#Discussion
    ///
    /// - Parameters:
    ///   - condition: The condition to request the review.
    ///   - view: The view that StoreKit uses to present the rating and review request interface.
    @available(iOS 16.0, *)
    public static func requestReview(_ condition: RequestReviewCondition, in view: UIView) {
        let runtimeContext = sharedSUKRuntimeState.snapshot()
        let preflightToken = reviewRequestPreflightToken(condition,
                                                         userDefaults: runtimeContext.userDefaults)

        DispatchQueue.main.async {
            if let scene = view.window?.windowScene {
                guard let context = prepareReviewRequest(condition,
                                                         preflightToken: preflightToken)
                else { return }

                defer { context.finish() }
                guard context.isCurrent() else { return }
                AppStore.requestReview(in: scene)
            }
        }
    }
    #endif

    /// Resets the status for the current environment: stored dates of version check and request
    /// review conditions in persistent and in-memory storage, and the stored app version for the
    /// release notes.
    /// The reset completes synchronously and invalidates in-flight and queued scheduling work,
    /// including update alerts that have not been presented yet. An alert already on screen keeps
    /// its update action.
    /// For example, you may use this method during testing and development.
    public static func reset() {
        let userDefaults = SUKUserDefaults.standard
        let schedulingKeys = [SwiftyUpdateKitLastVersionCheckDateKey,
                              SwiftyUpdateKitLastRequireReviewDateKey]
        let persistentStore = UserDefaultsSchedulingStateStore()
        let inMemoryStore = InMemorySchedulingStateStore()
        let contexts = schedulingKeys.map {
            SchedulingStateContext(userDefaults: userDefaults, key: $0)
        }

        sharedSchedulingExecutionGate.reset(for: userDefaults) {
            for context in contexts {
                persistentStore.removeValue(for: context)
                inMemoryStore.removeValue(for: context)
            }

            // Release-note updates use the same gate, so clearing this value inside the critical
            // section prevents stale operations from restoring it after reset.
            userDefaults.removeObject(forKey: SwiftyUpdateKitLatestAppVersionKey)
        }
    }
}

extension SUK {
    static func checkVersion(_ condition: VersionCheckCondition,
                             update: UpdateHandler?,
                             newRelease: NewReleaseHandler?,
                             forUserID userID: String,
                             noop: (() -> Void)?,
                             lookup: AppStoreLookup)
    {
        checkVersion(condition, update: update, lookup: lookup) { lookUpResult, context in
            guard context.isCurrent() else { return }

            guard let newRelease else {
                // Not need to show the new release.
                noop?()
                return
            }

            if let result = lookUpResult {
                // Use fetched lookUpResult.
                checkNewRelease(result,
                                context: context,
                                newRelease: newRelease,
                                forUserID: userID,
                                noop: noop)
            } else {
                lookup.lookUp(with: context.config) { result in
                    switch result {
                        case let .failure(error):
                            // Ignore an error.
                            context.writeLog(error.localizedDescription)
                            DispatchQueue.main.async {
                                guard context.isCurrent() else { return }
                                noop?()
                            }
                        case let .success(lookUpResults):
                            guard let lookUpResult = lookUpResults.first else {
                                // Ignore an error.
                                context
                                    .writeLog("lookUpResult does not exist in the response data.")
                                DispatchQueue.main.async {
                                    guard context.isCurrent() else { return }
                                    noop?()
                                }
                                return
                            }

                            checkNewRelease(lookUpResult,
                                            context: context,
                                            newRelease: newRelease,
                                            forUserID: userID,
                                            noop: noop)
                    }
                }
            }
        }
    }

    private static func checkVersion(_ condition: VersionCheckCondition,
                                     update: UpdateHandler?,
                                     lookup: AppStoreLookup,
                                     next: @escaping (LookUpResult?, VersionCheckOperationContext)
                                         -> Void)
    {
        let runtimeContext = sharedSUKRuntimeState.snapshot()
        let executionController = condition as? VersionCheckExecutionControlling
        let preflightToken = executionController?
            .versionCheckPreflightToken(in: runtimeContext.userDefaults)
            ?? sharedSchedulingExecutionGate.token(for: runtimeContext.userDefaults)

        DispatchQueue.main.async {
            let isPreflightCurrent = executionController?
                .isCurrentVersionCheck(preflightToken)
                ?? sharedSchedulingExecutionGate.isCurrent(preflightToken)
            guard isPreflightCurrent else { return }

            guard let config = runtimeContext.config else {
                logf("`applicationDidFinishLaunching(withConfig:)` method is not called yet.",
                     runtimeContext.log)
                return
            }

            let userDefaults = runtimeContext.userDefaults
            let preflightContext = VersionCheckOperationContext(config: config,
                                                                logger: runtimeContext.log,
                                                                userDefaults: userDefaults,
                                                                token: preflightToken,
                                                                executionController:
                                                                executionController)
            let isEligible = SchedulingExecutionScope.withToken(preflightToken) {
                condition.shouldCheckVersion()
            }

            guard preflightContext.isCurrent() else {
                preflightContext.writeLog(versionCheckInvalidatedLog)
                return
            }

            guard isEligible else {
                preflightContext.writeLog("Skips the version check because its condition declined.")
                DispatchQueue.main.async {
                    guard preflightContext.isCurrent() else { return }
                    next(nil, preflightContext)
                }
                return
            }

            let decision: SchedulingExecutionDecision

            if let executionController {
                decision = executionController.beginVersionCheck(in: userDefaults,
                                                                 preflightToken: preflightToken)
            } else {
                decision = .started(preflightToken)
            }

            switch decision {
                case let .started(token):
                    let context = VersionCheckOperationContext(config: config,
                                                               logger: runtimeContext.log,
                                                               userDefaults: userDefaults,
                                                               token: token,
                                                               executionController:
                                                               executionController)

                    performVersionLookup(condition,
                                         update: update,
                                         lookup: lookup,
                                         context: context,
                                         next: next)
                case .inProgress:
                    logf("Skips the version check because a lookup is already in progress.",
                         runtimeContext.log)
                case let .invalidated(token):
                    let context = VersionCheckOperationContext(config: config,
                                                               logger: runtimeContext.log,
                                                               userDefaults: userDefaults,
                                                               token: token,
                                                               executionController:
                                                               executionController)
                    context.finish()
                    context.writeLog(versionCheckInvalidatedLog)
            }
        }
    }

    private static func performVersionLookup(_ condition: VersionCheckCondition,
                                             update: UpdateHandler?,
                                             lookup: AppStoreLookup,
                                             context: VersionCheckOperationContext,
                                             next: @escaping (LookUpResult?,
                                                              VersionCheckOperationContext) -> Void)
    {
        lookup.lookUp(with: context.config) { result in
            switch result {
                case let .failure(error):
                    // Ignore an error.
                    context.writeLog(error.localizedDescription)
                    context.finish()
                case let .success(lookUpResults):
                    context.writeLog(lookUpResults.description)
                    guard let lookUpResult = lookUpResults.first,
                          let storeVersion = lookUpResult.version
                    else {
                        // Ignore an error.
                        context.writeLog("version does not exist in the response data.")
                        context.finish()
                        return
                    }

                    let isStillCurrent = context.recordSuccessfulVersionCheck(condition)
                    context.finish()
                    guard isStillCurrent else { return }

                    let isOld = context.config.versionCompare.compare(storeVersion,
                                                                      with: context.config.version)
                    guard context.isCurrent() else { return }

                    if isOld {
                        context.writeLog("This app version is old.")

                        if let update {
                            DispatchQueue.main.async {
                                guard context.isCurrent() else { return }
                                update(lookUpResult.version, lookUpResult.releaseNotes)
                            }
                        } else {
                            enqueueUpdateAlert(config: context.config,
                                               log: context.logger,
                                               isCurrent: { context.isCurrent() },
                                               presenter: { config, updateAction in
                                                   presentUpdateAlert(config,
                                                                      updateAction: updateAction)
                                               },
                                               openURL: { url in
                                                   openAppStoreURL(url)
                                               })
                        }
                    } else {
                        // Latest
                        context.writeLog("This app version is already latest.")
                        DispatchQueue.main.async {
                            guard context.isCurrent() else { return }
                            next(lookUpResult, context)
                        }
                    }
            }
        }
    }

    /// Synchronously exercises review scheduling without invoking StoreKit from unit tests.
    static func requestReviewIfNeededForTesting(_ condition: RequestReviewCondition,
                                                request: () -> Void)
    {
        let runtimeContext = sharedSUKRuntimeState.snapshot()
        let preflightToken = reviewRequestPreflightToken(condition,
                                                         userDefaults: runtimeContext.userDefaults)
        guard let context = prepareReviewRequest(condition, preflightToken: preflightToken)
        else { return }

        defer { context.finish() }
        guard context.isCurrent() else { return }
        request()
    }

    static func enqueueReviewRequest(_ condition: RequestReviewCondition,
                                     request: @escaping @MainActor () -> Void)
    {
        let runtimeContext = sharedSUKRuntimeState.snapshot()
        let preflightToken = reviewRequestPreflightToken(condition,
                                                         userDefaults: runtimeContext.userDefaults)

        DispatchQueue.main.async {
            guard let context = prepareReviewRequest(condition,
                                                     preflightToken: preflightToken)
            else { return }

            defer { context.finish() }
            guard context.isCurrent() else { return }
            request()
        }
    }

    private static func prepareReviewRequest(_ condition: RequestReviewCondition,
                                             preflightToken: SchedulingExecutionToken)
        -> ReviewRequestOperationContext?
    {
        let userDefaults = preflightToken.userDefaults
        let executionController = condition as? ReviewRequestExecutionControlling
        let isPreflightCurrent = executionController?
            .isCurrentReviewRequest(preflightToken)
            ?? sharedSchedulingExecutionGate.isCurrent(preflightToken)
        guard isPreflightCurrent else { return nil }

        let isEligible = SchedulingExecutionScope.withToken(preflightToken) {
            condition.shouldRequestReview()
        }
        let isStillCurrent = executionController?
            .isCurrentReviewRequest(preflightToken)
            ?? sharedSchedulingExecutionGate.isCurrent(preflightToken)
        guard isEligible, isStillCurrent else { return nil }

        let decision: SchedulingExecutionDecision

        if let executionController {
            decision = executionController.beginReviewRequest(in: userDefaults,
                                                              preflightToken: preflightToken)
        } else {
            decision = .started(preflightToken)
        }

        guard case let .started(token) = decision else { return nil }

        let context = ReviewRequestOperationContext(token: token,
                                                    executionController: executionController)
        guard context.isCurrent() else {
            context.finish()
            return nil
        }

        if let recordingCondition = condition as? ReviewRequestAttemptRecording {
            SchedulingExecutionScope.withToken(token) {
                recordingCondition.recordReviewRequestAttempt()
            }
        }

        guard context.isCurrent() else {
            context.finish()
            return nil
        }

        return context
    }

    private static func reviewRequestPreflightToken(_ condition: RequestReviewCondition,
                                                    userDefaults: SUKUserDefaults)
        -> SchedulingExecutionToken
    {
        if let executionController = condition as? ReviewRequestExecutionControlling {
            return executionController.reviewRequestPreflightToken(in: userDefaults)
        }

        return sharedSchedulingExecutionGate.token(for: userDefaults)
    }

    private static func checkNewRelease(_ lookUpResult: LookUpResult,
                                        context: VersionCheckOperationContext,
                                        newRelease: @escaping NewReleaseHandler,
                                        forUserID userID: String,
                                        noop: (() -> Void)?)
    {
        guard context.isCurrent() else { return }

        guard let storeVersion = lookUpResult.version else {
            context.writeLog("version does not exist in the response data.")
            return
        }

        guard storeVersion == context.config.version else {
            let message =
                "Current app version is not equal to the version released on the App Store."
            context.writeLog(message)
            DispatchQueue.main.async {
                guard context.isCurrent() else { return }
                noop?()
            }
            return
        }

        var savedVersion: String?
        guard context.performStateAccessIfCurrent({
            savedVersion = ReleaseNotes.first(forUserID: userID,
                                              userDefaults: context.userDefaults).latest
        }) else { return }

        guard let savedVersion else {
            // First updated.
            context.writeLog("A user has installed the app firstly.")
            guard context.performStateAccessIfCurrent({
                ReleaseNotes.update(storeVersion,
                                    forUserID: userID,
                                    userDefaults: context.userDefaults)
            }) else { return }

            DispatchQueue.main.async {
                guard context.isCurrent() else { return }
                newRelease(storeVersion, lookUpResult.releaseNotes, true)
            }
            return
        }

        let isNewRelease = context.config.versionCompare.compare(storeVersion, with: savedVersion)
        guard context.isCurrent() else { return }

        guard isNewRelease else {
            context.writeLog("Saved app version is already latest.")
            DispatchQueue.main.async {
                guard context.isCurrent() else { return }
                noop?()
            }
            return
        }

        guard context.performStateAccessIfCurrent({
            ReleaseNotes.update(storeVersion,
                                forUserID: userID,
                                userDefaults: context.userDefaults)
        }) else { return }

        DispatchQueue.main.async {
            guard context.isCurrent() else { return }
            newRelease(storeVersion, lookUpResult.releaseNotes, false)
        }
    }
}
