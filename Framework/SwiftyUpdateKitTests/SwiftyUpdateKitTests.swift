//
//  SwiftyUpdateKitTests.swift
//  SwiftyUpdateKitTests
//
//  Copyright © 2021 Hituzi Ando. All rights reserved.
//

@testable import SwiftyUpdateKit
import XCTest

class SwiftyUpdateKitTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in
        // the class.
        SUKUserDefaults.setEnvironment(.test)
        SUK.reset()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in
        // the class.
    }

    func testVersion() throws {
        XCTAssertNotNil(SUK.version)
    }

    func testReset() throws {
        // Set test data.
        let ud = SUKUserDefaults.standard
        ud.set(DateUtils.currentDate(), forKey: SwiftyUpdateKitLastVersionCheckDateKey)
        ud.set(DateUtils.currentDate(), forKey: SwiftyUpdateKitLastRequireReviewDateKey)
        ReleaseNotes.update("1.2.2", forUserID: "Test")

        SUK.reset()

        XCTAssertEqual(0, ud.integer(forKey: SwiftyUpdateKitLastVersionCheckDateKey))
        XCTAssertEqual(0, ud.integer(forKey: SwiftyUpdateKitLastRequireReviewDateKey))
        XCTAssertNil(ud.string(forKey: SwiftyUpdateKitLatestAppVersionKey))
    }

    func testUse_Development_DB() throws {
        let config = SwiftyUpdateKitConfig(version: "1.2.3",
                                           iTunesID: "1491913803",
                                           storeURL: "https://apps.apple.com/app/blue-sketch/id1491913803",
                                           development: true)
        SUK.initialize(withConfig: config)

        XCTAssertTrue(SUKUserDefaults.standard.env == .development)
    }

    func testUse_Production_DB_By_Default() throws {
        let config = SwiftyUpdateKitConfig(version: "1.2.3",
                                           iTunesID: "1491913803",
                                           storeURL: "https://apps.apple.com/app/blue-sketch/id1491913803")
        SUK.initialize(withConfig: config)

        XCTAssertTrue(SUKUserDefaults.standard.env == .production)
    }
}

final class ResetTests: XCTestCase {
    override func setUpWithError() throws {
        SUKUserDefaults.setEnvironment(.test)
        SUK.reset()
    }

    override func tearDownWithError() throws {
        for environment in [SUKUserDefaults.Environment.production, .development, .test] {
            SUKUserDefaults.setEnvironment(environment)
            SUK.reset()
        }
    }

    func testResetRestoresAllVersionCheckConditions() {
        let always = VersionCheckConditionAlways()
        let disable = VersionCheckConditionDisable()
        let daily = VersionCheckConditionDaily()
        let launchingAndDaily = VersionCheckConditionLaunchingAndDaily()

        XCTAssertTrue(always.shouldCheckVersion())
        XCTAssertFalse(disable.shouldCheckVersion())
        XCTAssertTrue(daily.shouldCheckVersion())
        XCTAssertTrue(launchingAndDaily.shouldCheckVersion())

        daily.recordSuccessfulVersionCheck()
        launchingAndDaily.recordSuccessfulVersionCheck()

        XCTAssertFalse(daily.shouldCheckVersion())
        XCTAssertFalse(launchingAndDaily.shouldCheckVersion())

        SUK.reset()

        XCTAssertTrue(always.shouldCheckVersion())
        XCTAssertFalse(disable.shouldCheckVersion())
        XCTAssertTrue(daily.shouldCheckVersion())
        XCTAssertTrue(launchingAndDaily.shouldCheckVersion())
    }

    func testResetPreservesStatelessReviewRequestConditions() {
        let always = RequestReviewConditionAlways()
        let disable = RequestReviewConditionDisable()

        XCTAssertTrue(always.shouldRequestReview())
        XCTAssertFalse(disable.shouldRequestReview())

        SUK.reset()

        XCTAssertTrue(always.shouldRequestReview())
        XCTAssertFalse(disable.shouldRequestReview())
    }

    func testResetRestoresDailyReviewRequestCondition() {
        let daily = RequestReviewConditionDaily()

        XCTAssertTrue(daily.shouldRequestReview())
        daily.recordReviewRequestAttempt()
        XCTAssertFalse(daily.shouldRequestReview())

        SUK.reset()

        XCTAssertTrue(daily.shouldRequestReview())
    }

    func testResetRestartsDailySkipFirstDayReviewRequestCondition() {
        let userDefaults = SUKUserDefaults.standard
        let stateContext = SchedulingStateContext(userDefaults: userDefaults,
                                                  key: SwiftyUpdateKitLastRequireReviewDateKey)
        let persistentStore = UserDefaultsSchedulingStateStore()
        let condition = RequestReviewConditionDailySkipFirstDay()

        XCTAssertFalse(condition.shouldRequestReview())
        XCTAssertNotEqual(persistentStore.integer(for: stateContext), 0)

        SUK.reset()

        XCTAssertEqual(persistentStore.integer(for: stateContext), 0)
        XCTAssertFalse(condition.shouldRequestReview())
    }

    func testResetRestoresLaunchingAndDailyReviewRequestCondition() {
        let condition = RequestReviewConditionLaunchingAndDaily()

        XCTAssertTrue(condition.shouldRequestReview())
        condition.recordReviewRequestAttempt()
        XCTAssertFalse(condition.shouldRequestReview())

        SUK.reset()

        XCTAssertTrue(condition.shouldRequestReview())
    }

    func testResetRestartsLaunchingAndDailySkipFirstDayReviewRequestCondition() {
        let userDefaults = SUKUserDefaults.standard
        let stateContext = SchedulingStateContext(userDefaults: userDefaults,
                                                  key: SwiftyUpdateKitLastRequireReviewDateKey)
        let inMemoryStore = InMemorySchedulingStateStore()
        let condition = RequestReviewConditionLaunchingAndDailySkipFirstDay()

        XCTAssertFalse(condition.shouldRequestReview())
        XCTAssertNotEqual(inMemoryStore.integer(for: stateContext), 0)

        SUK.reset()

        XCTAssertEqual(inMemoryStore.integer(for: stateContext), 0)
        XCTAssertFalse(condition.shouldRequestReview())
    }

    func testResetRestoresReleaseNotesState() {
        ReleaseNotes.update("1.2.3", forUserID: "Test")
        XCTAssertEqual(ReleaseNotes.first(forUserID: "Test").latest, "1.2.3")

        SUK.reset()

        XCTAssertNil(ReleaseNotes.first(forUserID: "Test").latest)
    }

    func testResetDoesNotRemoveStateFromAnotherEnvironment() {
        let persistentStore = UserDefaultsSchedulingStateStore()
        let inMemoryStore = InMemorySchedulingStateStore()

        SUKUserDefaults.setEnvironment(.production)
        let productionUserDefaults = SUKUserDefaults.standard
        let versionKey = SwiftyUpdateKitLastVersionCheckDateKey
        let reviewKey = SwiftyUpdateKitLastRequireReviewDateKey
        let productionVersionContext = SchedulingStateContext(userDefaults: productionUserDefaults,
                                                              key: versionKey)
        let productionReviewContext = SchedulingStateContext(userDefaults: productionUserDefaults,
                                                             key: reviewKey)
        persistentStore.set(20_260_819, for: productionVersionContext)
        persistentStore.set(20_260_820, for: productionReviewContext)
        inMemoryStore.set(20_260_821, for: productionVersionContext)
        inMemoryStore.set(20_260_822, for: productionReviewContext)
        ReleaseNotes.update("1.2.3",
                            forUserID: "Production",
                            userDefaults: productionUserDefaults)

        SUKUserDefaults.setEnvironment(.development)
        let developmentUserDefaults = SUKUserDefaults.standard
        let developmentVersionContext =
            SchedulingStateContext(userDefaults: developmentUserDefaults,
                                   key: versionKey)
        let developmentReviewContext = SchedulingStateContext(userDefaults: developmentUserDefaults,
                                                              key: reviewKey)
        persistentStore.set(20_260_823, for: developmentVersionContext)
        persistentStore.set(20_260_824, for: developmentReviewContext)
        inMemoryStore.set(20_260_825, for: developmentVersionContext)
        inMemoryStore.set(20_260_826, for: developmentReviewContext)
        ReleaseNotes.update("2.0.0",
                            forUserID: "Development",
                            userDefaults: developmentUserDefaults)

        SUK.reset()

        XCTAssertEqual(persistentStore.integer(for: developmentVersionContext), 0)
        XCTAssertEqual(persistentStore.integer(for: developmentReviewContext), 0)
        XCTAssertEqual(inMemoryStore.integer(for: developmentVersionContext), 0)
        XCTAssertEqual(inMemoryStore.integer(for: developmentReviewContext), 0)
        XCTAssertNil(ReleaseNotes.first(forUserID: "Development",
                                        userDefaults: developmentUserDefaults).latest)

        SUKUserDefaults.setEnvironment(.production)

        XCTAssertEqual(persistentStore.integer(for: productionVersionContext), 20_260_819)
        XCTAssertEqual(persistentStore.integer(for: productionReviewContext), 20_260_820)
        XCTAssertEqual(inMemoryStore.integer(for: productionVersionContext), 20_260_821)
        XCTAssertEqual(inMemoryStore.integer(for: productionReviewContext), 20_260_822)
        XCTAssertEqual(ReleaseNotes.first(forUserID: "Production",
                                          userDefaults: productionUserDefaults).latest,
                       "1.2.3")
    }

    func testResetInvalidatesInFlightVersionCheckWithoutUnlockingReplacement() {
        initializeSUKForSchedulingTests()
        SUK.reset()

        let userDefaults = SUKUserDefaults.standard
        let stateStore = InMemorySchedulingStateStore()
        let stateContext = SchedulingStateContext(userDefaults: userDefaults,
                                                  key: SwiftyUpdateKitLastVersionCheckDateKey)
        let lookup = ControlledAppStoreLookup()

        checkVersion(VersionCheckConditionLaunchingAndDaily(), lookup: lookup)
        waitForMainQueue()
        XCTAssertEqual(lookup.requestCount, 1)

        SUK.reset()

        checkVersion(VersionCheckConditionLaunchingAndDaily(), lookup: lookup)
        waitForMainQueue()
        XCTAssertEqual(lookup.requestCount, 2)

        lookup.completeNext(with: .success([.stub(version: "1.0.0")]))
        waitForMainQueue()

        XCTAssertEqual(stateStore.integer(for: stateContext), 0)
        XCTAssertNil(ReleaseNotes.first(forUserID: "Test", userDefaults: userDefaults).latest)

        checkVersion(VersionCheckConditionLaunchingAndDaily(), lookup: lookup)
        waitForMainQueue()
        XCTAssertEqual(lookup.requestCount, 2)

        lookup.completeNext(with: .success([.stub(version: "1.0.0")]))
        waitForMainQueue()

        XCTAssertNotEqual(stateStore.integer(for: stateContext), 0)
        XCTAssertEqual(ReleaseNotes.first(forUserID: "Test", userDefaults: userDefaults).latest,
                       "1.0.0")
    }

    func testProductionAndDevelopmentInFlightChecksRemainIndependent() {
        initializeSUKForSchedulingTests(development: false)
        SUK.reset()

        let productionUserDefaults = SUKUserDefaults.standard
        let lookup = ControlledAppStoreLookup()

        checkVersion(VersionCheckConditionDaily(), lookup: lookup)
        waitForMainQueue()
        XCTAssertEqual(lookup.requestCount, 1)

        initializeSUKForSchedulingTests(development: true)
        SUK.reset()

        let developmentUserDefaults = SUKUserDefaults.standard

        checkVersion(VersionCheckConditionDaily(), lookup: lookup)
        waitForMainQueue()
        XCTAssertEqual(lookup.requestCount, 2)

        lookup.completeNext(with: .success([.stub(version: "1.0.0")]))
        waitForMainQueue()

        XCTAssertNotEqual(productionUserDefaults
            .integer(forKey: SwiftyUpdateKitLastVersionCheckDateKey),
            0)
        XCTAssertEqual(ReleaseNotes.first(forUserID: "Test",
                                          userDefaults: productionUserDefaults).latest,
                       "1.0.0")
        XCTAssertEqual(developmentUserDefaults
            .integer(forKey: SwiftyUpdateKitLastVersionCheckDateKey),
            0)
        XCTAssertNil(ReleaseNotes.first(forUserID: "Test",
                                        userDefaults: developmentUserDefaults).latest)

        lookup.completeNext(with: .success([.stub(version: "1.0.0")]))
        waitForMainQueue()

        XCTAssertNotEqual(developmentUserDefaults
            .integer(forKey: SwiftyUpdateKitLastVersionCheckDateKey),
            0)
        XCTAssertEqual(ReleaseNotes.first(forUserID: "Test",
                                          userDefaults: developmentUserDefaults).latest,
                       "1.0.0")
    }
}

final class SchedulingInvalidationTests: XCTestCase {
    override func setUpWithError() throws {
        SUKUserDefaults.setEnvironment(.test)
        SUK.reset()
    }

    override func tearDownWithError() throws {
        for environment in [SUKUserDefaults.Environment.production, .development, .test] {
            SUKUserDefaults.setEnvironment(environment)
            SUK.reset()
        }
    }

    func testDailyVersionCheckInvokesSubclassOverrides() {
        initializeSUKForSchedulingTests()
        SUK.reset()

        let lookup = ControlledAppStoreLookup()
        let ineligibleCondition = IneligibleDailyVersionCheckCondition()

        SUK.checkVersion(ineligibleCondition,
                         update: nil,
                         newRelease: nil,
                         forUserID: "Test",
                         noop: nil,
                         lookup: lookup)
        waitForMainQueue()

        XCTAssertEqual(ineligibleCondition.eligibilityCallCount, 1)
        XCTAssertEqual(lookup.requestCount, 0)

        SUK.reset()

        let recordingCondition = RecordingDailyVersionCheckCondition()
        SUK.checkVersion(recordingCondition,
                         update: nil,
                         newRelease: nil,
                         forUserID: "Test",
                         noop: nil,
                         lookup: lookup)
        waitForMainQueue()
        XCTAssertEqual(lookup.requestCount, 1)

        lookup.completeNext(with: .success([.stub(version: "1.0.0")]))
        waitForMainQueue()

        XCTAssertEqual(recordingCondition.recordingCallCount, 1)
        XCTAssertNotEqual(SUKUserDefaults.standard
            .integer(forKey: SwiftyUpdateKitLastVersionCheckDateKey),
            0)
    }

    func testLaunchingAndDailyVersionCheckInvokesSubclassOverrides() {
        initializeSUKForSchedulingTests()
        SUK.reset()

        let lookup = ControlledAppStoreLookup()
        let ineligibleCondition = IneligibleLaunchingAndDailyVersionCheckCondition()

        SUK.checkVersion(ineligibleCondition,
                         update: nil,
                         newRelease: nil,
                         forUserID: "Test",
                         noop: nil,
                         lookup: lookup)
        waitForMainQueue()

        XCTAssertEqual(ineligibleCondition.eligibilityCallCount, 1)
        XCTAssertEqual(lookup.requestCount, 0)

        SUK.reset()

        let recordingCondition = RecordingLaunchingAndDailyVersionCheckCondition()
        SUK.checkVersion(recordingCondition,
                         update: nil,
                         newRelease: nil,
                         forUserID: "Test",
                         noop: nil,
                         lookup: lookup)
        waitForMainQueue()
        XCTAssertEqual(lookup.requestCount, 1)

        lookup.completeNext(with: .success([.stub(version: "1.0.0")]))
        waitForMainQueue()

        let stateContext = SchedulingStateContext(userDefaults: SUKUserDefaults.standard,
                                                  key: SwiftyUpdateKitLastVersionCheckDateKey)
        XCTAssertEqual(recordingCondition.recordingCallCount, 1)
        XCTAssertNotEqual(InMemorySchedulingStateStore().integer(for: stateContext), 0)
    }

    func testReentrantVersionComparisonResetDoesNotPublishStaleEffects() {
        let comparisonCompleted = expectation(description: "Version comparison completed")
        let comparator = ResettingVersionCompare {
            comparisonCompleted.fulfill()
        }
        let config = schedulingTestConfig(version: "1.0.0", versionCompare: comparator)
        SUK.initialize(withConfig: config)
        SUK.reset()

        let userDefaults = SUKUserDefaults.standard
        var callbackCount = 0
        let lookup = StubAppStoreLookup(result: .success([.stub(version: "2.0.0")]))

        SUK.checkVersion(VersionCheckConditionDaily(),
                         update: { _, _ in callbackCount += 1 },
                         newRelease: { _, _, _ in callbackCount += 1 },
                         forUserID: "Test",
                         noop: { callbackCount += 1 },
                         lookup: lookup)

        wait(for: [comparisonCompleted], timeout: 1)
        waitForMainQueue()

        XCTAssertEqual(callbackCount, 0)
        XCTAssertEqual(userDefaults.integer(forKey: SwiftyUpdateKitLastVersionCheckDateKey), 0)
        XCTAssertNil(ReleaseNotes.first(forUserID: "Test", userDefaults: userDefaults).latest)
    }

    func testQueuedUpdateAlertIsCancelledAfterReset() {
        let config = schedulingTestConfig(version: "1.0.0")
        SUK.initialize(withConfig: config)
        SUK.reset()

        let token = sharedSchedulingExecutionGate.token(for: SUKUserDefaults.standard)
        var presentationCount = 0
        var openCount = 0

        SUK.enqueueUpdateAlert(config: config,
                               log: nil,
                               isCurrent: {
                                   sharedSchedulingExecutionGate.isCurrent(token)
                               },
                               presenter: { _, _ in
                                   presentationCount += 1
                               },
                               openURL: { _ in
                                   openCount += 1
                               })

        SUK.reset()
        waitForMainQueue()

        XCTAssertEqual(presentationCount, 0)
        XCTAssertEqual(openCount, 0)
    }

    func testQueuedUpdateAlertUsesCapturedConfigurationAndStoreURL() {
        let originalStoreURL = "https://apps.apple.com/app/id1111111111"
        let replacementStoreURL = "https://apps.apple.com/app/id2222222222"
        let originalConfig = schedulingTestConfig(version: "1.0.0",
                                                  storeURL: originalStoreURL,
                                                  updateAlertTitle: "Original title",
                                                  development: false)
        SUK.initialize(withConfig: originalConfig)
        SUK.reset()

        let token = sharedSchedulingExecutionGate.token(for: SUKUserDefaults.standard)
        var presentedConfig: SwiftyUpdateKitConfig?
        var updateAction: (() -> Void)?
        var openedURL: URL?

        SUK.enqueueUpdateAlert(config: originalConfig,
                               log: nil,
                               isCurrent: {
                                   sharedSchedulingExecutionGate.isCurrent(token)
                               },
                               presenter: { config, action in
                                   presentedConfig = config
                                   updateAction = action
                               },
                               openURL: { url in
                                   openedURL = url
                               })

        SUK.initialize(withConfig: schedulingTestConfig(version: "2.0.0",
                                                        storeURL: replacementStoreURL,
                                                        updateAlertTitle: "Replacement title",
                                                        development: true))
        waitForMainQueue()

        XCTAssertEqual(presentedConfig?.updateAlertTitle, "Original title")
        XCTAssertNil(openedURL)

        updateAction?()

        XCTAssertEqual(openedURL?.absoluteString, originalStoreURL)
    }

    func testPresentedUpdateAlertActionStillOpensCapturedStoreURLAfterReset() {
        let config = schedulingTestConfig(version: "1.0.0",
                                          storeURL: "https://apps.apple.com/app/id1111111111")
        SUK.initialize(withConfig: config)
        SUK.reset()

        let token = sharedSchedulingExecutionGate.token(for: SUKUserDefaults.standard)
        var updateAction: (() -> Void)?
        var openedURL: URL?

        SUK.enqueueUpdateAlert(config: config,
                               log: nil,
                               isCurrent: {
                                   sharedSchedulingExecutionGate.isCurrent(token)
                               },
                               presenter: { _, action in
                                   updateAction = action
                               },
                               openURL: { url in
                                   openedURL = url
                               })
        waitForMainQueue()

        XCTAssertNotNil(updateAction)

        SUK.reset()
        updateAction?()

        XCTAssertEqual(openedURL?.absoluteString,
                       "https://apps.apple.com/app/id1111111111")
    }

    func testReviewRequestInvokesSubclassOverrides() {
        initializeSUKForSchedulingTests()
        SUK.reset()

        let ineligibleCondition = IneligibleDailyReviewCondition()
        var requestCount = 0
        SUK.requestReviewIfNeededForTesting(ineligibleCondition) {
            requestCount += 1
        }

        XCTAssertEqual(ineligibleCondition.eligibilityCallCount, 1)
        XCTAssertEqual(requestCount, 0)

        let recordingCondition = RecordingLaunchingAndDailyReviewCondition()
        SUK.requestReviewIfNeededForTesting(recordingCondition) {
            requestCount += 1
        }

        XCTAssertEqual(recordingCondition.recordingCallCount, 1)
        XCTAssertEqual(requestCount, 1)
    }

    func testResetInvalidatesPersistentReviewRecordingInProgress() {
        initializeSUKForSchedulingTests()
        SUK.reset()

        let started = DispatchSemaphore(value: 0)
        let proceed = DispatchSemaphore(value: 0)
        let requestCount = LockedCounter()
        let operationCompleted = expectation(description: "Review operation completed")
        let condition = BlockingDailyReviewCondition(recordingStarted: started,
                                                     continueRecording: proceed)

        DispatchQueue.global().async {
            SUK.requestReviewIfNeededForTesting(condition) {
                requestCount.increment()
            }
            operationCompleted.fulfill()
        }

        XCTAssertEqual(started.wait(timeout: .now() + 1), .success)
        SUK.reset()
        proceed.signal()
        wait(for: [operationCompleted], timeout: 1)

        XCTAssertEqual(requestCount.value, 0)
        XCTAssertEqual(SUKUserDefaults.standard
            .integer(forKey: SwiftyUpdateKitLastRequireReviewDateKey),
            0)
    }

    func testResetInvalidatesInMemoryReviewRecordingInProgress() {
        initializeSUKForSchedulingTests()
        SUK.reset()

        let userDefaults = SUKUserDefaults.standard
        let started = DispatchSemaphore(value: 0)
        let proceed = DispatchSemaphore(value: 0)
        let requestCount = LockedCounter()
        let operationCompleted = expectation(description: "Review operation completed")
        let condition = BlockingLaunchingAndDailyReviewCondition(recordingStarted: started,
                                                                 continueRecording: proceed)

        DispatchQueue.global().async {
            SUK.requestReviewIfNeededForTesting(condition) {
                requestCount.increment()
            }
            operationCompleted.fulfill()
        }

        XCTAssertEqual(started.wait(timeout: .now() + 1), .success)
        SUK.reset()
        proceed.signal()
        wait(for: [operationCompleted], timeout: 1)

        let stateContext = SchedulingStateContext(userDefaults: userDefaults,
                                                  key: SwiftyUpdateKitLastRequireReviewDateKey)
        XCTAssertEqual(requestCount.value, 0)
        XCTAssertEqual(InMemorySchedulingStateStore().integer(for: stateContext), 0)
    }

    func testConcurrentRuntimeSnapshotsKeepConfigurationLogAndEnvironmentTogether() {
        let runtimeState = SUKRuntimeState()
        let mismatches = AtomicDictionary<Int, Bool>()
        let productionConfig = schedulingTestConfig(version: "production", development: false)
        let developmentConfig = schedulingTestConfig(version: "development", development: true)
        let productionLog: Log = { message in
            if message as? String != "production" {
                mismatches.setValue(true, forKey: 0)
            }
        }
        let developmentLog: Log = { message in
            if message as? String != "development" {
                mismatches.setValue(true, forKey: 1)
            }
        }

        DispatchQueue.concurrentPerform(iterations: 1_000) { iteration in
            if iteration.isMultiple(of: 2) {
                runtimeState.initialize(config: productionConfig, log: productionLog)
            } else {
                runtimeState.initialize(config: developmentConfig, log: developmentLog)
            }

            let snapshot = runtimeState.snapshot()
            guard let config = snapshot.config else {
                mismatches.setValue(true, forKey: 2)
                return
            }

            let expectedEnvironment: SUKUserDefaults.Environment =
                config.isDevelopment ? .development : .production
            if snapshot.userDefaults.env != expectedEnvironment {
                mismatches.setValue(true, forKey: 3)
            }
            snapshot.log?(config.version)
        }

        for key in 0 ... 3 {
            XCTAssertNil(mismatches.value(forKey: key))
        }
    }

    func testResetBeforeQueuedVersionCheckPreventsPersistentOperation() {
        initializeSUKForSchedulingTests()
        SUK.reset()

        let userDefaults = SUKUserDefaults.standard
        let lookup = ControlledAppStoreLookup()

        checkVersion(VersionCheckConditionDaily(), lookup: lookup)
        SUK.reset()
        waitForMainQueue()

        XCTAssertEqual(lookup.requestCount, 0)
        XCTAssertEqual(userDefaults.integer(forKey: SwiftyUpdateKitLastVersionCheckDateKey), 0)
    }

    func testResetBeforeQueuedReviewRequestPreventsInMemoryOperation() {
        initializeSUKForSchedulingTests()
        SUK.reset()

        let userDefaults = SUKUserDefaults.standard
        let stateContext = SchedulingStateContext(userDefaults: userDefaults,
                                                  key: SwiftyUpdateKitLastRequireReviewDateKey)
        var requestCount = 0

        SUK.enqueueReviewRequest(RequestReviewConditionLaunchingAndDaily()) {
            requestCount += 1
        }
        SUK.reset()
        waitForMainQueue()

        XCTAssertEqual(requestCount, 0)
        XCTAssertEqual(InMemorySchedulingStateStore().integer(for: stateContext), 0)
    }
}

final class AtomicDictionaryTests: XCTestCase {
    func testConcurrentReadWriteAndRemove() {
        let dictionary = AtomicDictionary<Int, Int>()

        DispatchQueue.concurrentPerform(iterations: 1_000) { iteration in
            let key = iteration % 16
            dictionary.setValue(iteration, forKey: key)
            _ = dictionary.value(forKey: key)
            dictionary.removeValue(forKey: key)
        }

        dictionary.setValue(42, forKey: 0)
        XCTAssertEqual(dictionary.value(forKey: 0), 42)
        XCTAssertEqual(dictionary.removeValue(forKey: 0), 42)
        XCTAssertNil(dictionary.value(forKey: 0))
    }
}

final class SchedulingConditionTests: XCTestCase {
    override func setUpWithError() throws {
        SUKUserDefaults.setEnvironment(.test)
        SUK.reset()
    }

    override func tearDownWithError() throws {
        for environment in [SUKUserDefaults.Environment.production, .development, .test] {
            SUKUserDefaults.setEnvironment(environment)
            SUK.reset()
        }
    }

    func testDailyVersionCheckRecordsOnlyAfterSuccess() {
        let clock = TestClock(currentDate: 20_260_819)
        let stateStore = TestSchedulingStateStore()
        let condition = VersionCheckConditionDaily(clock: clock, stateStore: stateStore)
        let stateContext = SchedulingStateContext(userDefaults: SUKUserDefaults.standard,
                                                  key: SwiftyUpdateKitLastVersionCheckDateKey)

        XCTAssertTrue(condition.shouldCheckVersion())
        XCTAssertTrue(condition.shouldCheckVersion())
        XCTAssertEqual(stateStore.writeCount, 0)

        condition.recordSuccessfulVersionCheck()
        condition.recordSuccessfulVersionCheck()

        XCTAssertEqual(stateStore.writeCount, 1)
        XCTAssertEqual(stateStore.integer(for: stateContext), 20_260_819)
        XCTAssertFalse(condition.shouldCheckVersion())

        clock.date = 20_260_820
        XCTAssertTrue(condition.shouldCheckVersion())
    }

    func testLaunchingAndDailyVersionCheckUsesSameTransitionRules() {
        let clock = TestClock(currentDate: 20_260_819)
        let stateStore = TestSchedulingStateStore()
        let condition = VersionCheckConditionLaunchingAndDaily(clock: clock,
                                                               stateStore: stateStore)

        XCTAssertTrue(condition.shouldCheckVersion())
        XCTAssertEqual(stateStore.writeCount, 0)

        condition.recordSuccessfulVersionCheck()

        XCTAssertEqual(stateStore.writeCount, 1)
        XCTAssertFalse(condition.shouldCheckVersion())

        clock.date = 20_260_820
        XCTAssertTrue(condition.shouldCheckVersion())
    }

    func testFinalLookupFailureDoesNotRecordSuccessfulCheck() {
        let clock = TestClock(currentDate: 20_260_819)
        let stateStore = TestSchedulingStateStore()
        let condition = VersionCheckConditionDaily(clock: clock, stateStore: stateStore)
        let lookupCompleted = expectation(description: "Lookup completed")
        initializeSUKForSchedulingTests()

        let lookup = StubAppStoreLookup(result: .failure(TestLookupError.failed)) {
            lookupCompleted.fulfill()
        }

        SUK.checkVersion(condition,
                         update: nil,
                         newRelease: nil,
                         forUserID: "Test",
                         noop: nil,
                         lookup: lookup)

        wait(for: [lookupCompleted], timeout: 1)
        XCTAssertEqual(stateStore.writeCount, 0)
        XCTAssertTrue(condition.shouldCheckVersion())
    }

    func testValidLookupRecordsSuccessfulCheckExactlyOnce() {
        let clock = TestClock(currentDate: 20_260_819)
        let stateStore = TestSchedulingStateStore()
        let condition = VersionCheckConditionDaily(clock: clock, stateStore: stateStore)
        let checkCompleted = expectation(description: "Check completed")
        initializeSUKForSchedulingTests()
        let stateContext = SchedulingStateContext(userDefaults: SUKUserDefaults.standard,
                                                  key: SwiftyUpdateKitLastVersionCheckDateKey)

        let lookup = StubAppStoreLookup(result: .success([.stub(version: "1.0.0")]))

        SUK.checkVersion(condition,
                         update: nil,
                         newRelease: nil,
                         forUserID: "Test",
                         noop: {
                             checkCompleted.fulfill()
                         },
                         lookup: lookup)

        wait(for: [checkCompleted], timeout: 1)
        XCTAssertEqual(stateStore.writeCount, 1)
        XCTAssertEqual(stateStore.integer(for: stateContext), 20_260_819)
        XCTAssertFalse(condition.shouldCheckVersion())
    }

    func testResponseWithoutVersionDoesNotRecordSuccessfulCheck() {
        let clock = TestClock(currentDate: 20_260_819)
        let stateStore = TestSchedulingStateStore()
        let condition = VersionCheckConditionDaily(clock: clock, stateStore: stateStore)
        let lookupCompleted = expectation(description: "Lookup completed")
        initializeSUKForSchedulingTests()

        let lookup = StubAppStoreLookup(result: .success([.stub(version: nil)])) {
            lookupCompleted.fulfill()
        }

        SUK.checkVersion(condition,
                         update: nil,
                         newRelease: nil,
                         forUserID: "Test",
                         noop: nil,
                         lookup: lookup)

        wait(for: [lookupCompleted], timeout: 1)
        XCTAssertEqual(stateStore.writeCount, 0)
        XCTAssertTrue(condition.shouldCheckVersion())
    }

    func testConcurrentLaunchingAndDailyChecksStartOneLookup() {
        let clock = TestClock(currentDate: 20_260_819)
        let stateStore = TestSchedulingStateStore()
        let executionGate = SchedulingExecutionGate()
        let firstCondition = VersionCheckConditionLaunchingAndDaily(clock: clock,
                                                                    stateStore: stateStore,
                                                                    executionGate: executionGate)
        let secondCondition = VersionCheckConditionLaunchingAndDaily(clock: clock,
                                                                     stateStore: stateStore,
                                                                     executionGate: executionGate)
        let lookup = ControlledAppStoreLookup()
        var noopCallCount = 0
        initializeSUKForSchedulingTests()

        checkVersion(firstCondition, lookup: lookup)
        checkVersion(secondCondition, lookup: lookup) {
            noopCallCount += 1
        }
        waitForMainQueue()

        XCTAssertEqual(lookup.requestCount, 1)
        XCTAssertEqual(noopCallCount, 0)
        XCTAssertEqual(stateStore.writeCount, 0)

        lookup.completeNext(with: .failure(TestLookupError.failed))
    }

    func testIneligibleVersionCheckCallsNoopWhileAnotherLookupIsInProgress() {
        let lookup = ControlledAppStoreLookup()
        let ineligibleCondition = IneligibleDailyVersionCheckCondition()
        var noopCallCount = 0
        initializeSUKForSchedulingTests()
        SUK.reset()

        SUK.checkVersion(VersionCheckConditionDaily(),
                         update: nil,
                         newRelease: nil,
                         forUserID: "Test",
                         noop: nil,
                         lookup: lookup)
        waitForMainQueue()
        XCTAssertEqual(lookup.requestCount, 1)

        SUK.checkVersion(ineligibleCondition,
                         update: nil,
                         newRelease: nil,
                         forUserID: "Test",
                         noop: {
                             noopCallCount += 1
                         },
                         lookup: lookup)
        waitForMainQueue()
        waitForMainQueue()

        XCTAssertEqual(ineligibleCondition.eligibilityCallCount, 1)
        XCTAssertEqual(noopCallCount, 1)
        XCTAssertEqual(lookup.requestCount, 1)

        lookup.completeNext(with: .failure(TestLookupError.failed))
    }

    func testLaunchingAndDailyCheckCanRetryAfterFailure() {
        let clock = TestClock(currentDate: 20_260_819)
        let stateStore = TestSchedulingStateStore()
        let executionGate = SchedulingExecutionGate()
        let firstCondition = VersionCheckConditionLaunchingAndDaily(clock: clock,
                                                                    stateStore: stateStore,
                                                                    executionGate: executionGate)
        let retryCondition = VersionCheckConditionLaunchingAndDaily(clock: clock,
                                                                    stateStore: stateStore,
                                                                    executionGate: executionGate)
        let lookup = ControlledAppStoreLookup()
        initializeSUKForSchedulingTests()

        checkVersion(firstCondition, lookup: lookup)
        waitForMainQueue()
        XCTAssertEqual(lookup.requestCount, 1)

        lookup.completeNext(with: .failure(TestLookupError.failed))

        checkVersion(retryCondition, lookup: lookup)
        waitForMainQueue()
        XCTAssertEqual(lookup.requestCount, 2)

        lookup.completeNext(with: .success([.stub(version: "1.0.0")]))
        waitForMainQueue()
        XCTAssertEqual(stateStore.writeCount, 1)
    }

    func testDailyReviewConditionRecordsRequestAttempt() {
        let clock = TestClock(currentDate: 20_260_819)
        let stateStore = TestSchedulingStateStore()
        let condition = RequestReviewConditionDaily(clock: clock, stateStore: stateStore)
        let stateContext = SchedulingStateContext(userDefaults: SUKUserDefaults.standard,
                                                  key: SwiftyUpdateKitLastRequireReviewDateKey)
        var requestCount = 0

        XCTAssertTrue(condition.shouldRequestReview())
        XCTAssertEqual(stateStore.writeCount, 0)

        SUK.requestReviewIfNeededForTesting(condition) {
            requestCount += 1
            XCTAssertEqual(stateStore.writeCount, 1)
        }

        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(stateStore.integer(for: stateContext), 20_260_819)
        XCTAssertFalse(condition.shouldRequestReview())
    }

    func testSkipFirstDayRecordsInitializationSeparatelyFromRequestAttempt() {
        let clock = TestClock(currentDate: 20_260_819)
        let stateStore = TestSchedulingStateStore()
        let condition = RequestReviewConditionDailySkipFirstDay(clock: clock,
                                                                stateStore: stateStore)
        let stateContext = SchedulingStateContext(userDefaults: SUKUserDefaults.standard,
                                                  key: SwiftyUpdateKitLastRequireReviewDateKey)
        var requestCount = 0

        SUK.requestReviewIfNeededForTesting(condition) {
            requestCount += 1
        }

        XCTAssertEqual(requestCount, 0)
        XCTAssertEqual(stateStore.writeCount, 1)
        XCTAssertEqual(stateStore.integer(for: stateContext), 20_260_819)

        clock.date = 20_260_820
        SUK.requestReviewIfNeededForTesting(condition) {
            requestCount += 1
        }

        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(stateStore.writeCount, 2)
        XCTAssertEqual(stateStore.integer(for: stateContext), 20_260_820)
    }
}

private final class IneligibleDailyVersionCheckCondition: VersionCheckConditionDaily {
    private(set) var eligibilityCallCount = 0

    override func shouldCheckVersion() -> Bool {
        eligibilityCallCount += 1
        return false
    }
}

private final class RecordingDailyVersionCheckCondition: VersionCheckConditionDaily {
    private(set) var recordingCallCount = 0

    override func recordSuccessfulVersionCheck() {
        recordingCallCount += 1
        super.recordSuccessfulVersionCheck()
    }
}

private final class IneligibleLaunchingAndDailyVersionCheckCondition:
    VersionCheckConditionLaunchingAndDaily
{
    private(set) var eligibilityCallCount = 0

    override func shouldCheckVersion() -> Bool {
        eligibilityCallCount += 1
        return false
    }
}

private final class RecordingLaunchingAndDailyVersionCheckCondition:
    VersionCheckConditionLaunchingAndDaily
{
    private(set) var recordingCallCount = 0

    override func recordSuccessfulVersionCheck() {
        recordingCallCount += 1
        super.recordSuccessfulVersionCheck()
    }
}

private final class IneligibleDailyReviewCondition: RequestReviewConditionDaily {
    private(set) var eligibilityCallCount = 0

    override func shouldRequestReview() -> Bool {
        eligibilityCallCount += 1
        return false
    }
}

private final class RecordingLaunchingAndDailyReviewCondition:
    RequestReviewConditionLaunchingAndDaily
{
    private(set) var recordingCallCount = 0

    override func recordReviewRequestAttempt() {
        recordingCallCount += 1
        super.recordReviewRequestAttempt()
    }
}

private final class BlockingDailyReviewCondition: RequestReviewConditionDaily {
    private let recordingStarted: DispatchSemaphore
    private let continueRecording: DispatchSemaphore

    init(recordingStarted: DispatchSemaphore, continueRecording: DispatchSemaphore) {
        self.recordingStarted = recordingStarted
        self.continueRecording = continueRecording
        super.init()
    }

    override func recordReviewRequestAttempt() {
        recordingStarted.signal()
        continueRecording.wait()
        super.recordReviewRequestAttempt()
    }
}

private final class BlockingLaunchingAndDailyReviewCondition:
    RequestReviewConditionLaunchingAndDaily
{
    private let recordingStarted: DispatchSemaphore
    private let continueRecording: DispatchSemaphore

    init(recordingStarted: DispatchSemaphore, continueRecording: DispatchSemaphore) {
        self.recordingStarted = recordingStarted
        self.continueRecording = continueRecording
        super.init()
    }

    override func recordReviewRequestAttempt() {
        recordingStarted.signal()
        continueRecording.wait()
        super.recordReviewRequestAttempt()
    }
}

private final class ResettingVersionCompare: VersionComparable {
    private let completion: () -> Void

    init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    func compare(_: String, with _: String) -> Bool {
        SUK.reset()
        completion()
        return true
    }
}

private final class LockedCounter {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        count += 1
    }
}

private final class TestClock: SUKClock {
    var date: Int

    init(currentDate: Int) {
        date = currentDate
    }

    func currentDate() -> Int {
        date
    }
}

private final class TestSchedulingStateStore: SUKSchedulingStateStore {
    private var values: [String: Int] = [:]
    private(set) var writeCount = 0

    func set(_ value: Int, for context: SchedulingStateContext) {
        values[context.storageKey] = value
        writeCount += 1
    }

    func integer(for context: SchedulingStateContext) -> Int {
        values[context.storageKey] ?? 0
    }

    func removeValue(for context: SchedulingStateContext) {
        values.removeValue(forKey: context.storageKey)
    }
}

private struct StubAppStoreLookup: AppStoreLookup {
    let result: Result<[LookUpResult], Error>
    let completionHandler: (() -> Void)?

    init(result: Result<[LookUpResult], Error>, completionHandler: (() -> Void)? = nil) {
        self.result = result
        self.completionHandler = completionHandler
    }

    func lookUp(with _: SwiftyUpdateKitConfig,
                completion: @escaping (Result<[LookUpResult], Error>) -> Void)
    {
        completion(result)
        completionHandler?()
    }
}

private final class ControlledAppStoreLookup: AppStoreLookup {
    private var completions: [(Result<[LookUpResult], Error>) -> Void] = []
    private(set) var requestCount = 0

    func lookUp(with _: SwiftyUpdateKitConfig,
                completion: @escaping (Result<[LookUpResult], Error>) -> Void)
    {
        requestCount += 1
        completions.append(completion)
    }

    func completeNext(with result: Result<[LookUpResult], Error>) {
        completions.removeFirst()(result)
    }
}

private enum TestLookupError: Error {
    case failed
}

private func initializeSUKForSchedulingTests(development: Bool = true) {
    SUK.initialize(withConfig: schedulingTestConfig(version: "1.0.0",
                                                    development: development))
}

private func schedulingTestConfig(version: String,
                                  storeURL: String = "https://apps.apple.com/app/id1234567890",
                                  updateAlertTitle: String = SwiftyUpdateKitConfig
                                      .defaultUpdateAlertTitle,
                                  versionCompare: VersionComparable? = nil,
                                  development: Bool = true) -> SwiftyUpdateKitConfig
{
    SwiftyUpdateKitConfig(version: version,
                          iTunesID: "1234567890",
                          storeURL: storeURL,
                          versionCompare: versionCompare,
                          updateAlertTitle: updateAlertTitle,
                          development: development)
}

private func checkVersion(_ condition: VersionCheckCondition,
                          lookup: AppStoreLookup,
                          noop: (() -> Void)? = nil)
{
    SUK.checkVersion(condition,
                     update: nil,
                     newRelease: { _, _, _ in },
                     forUserID: "Test",
                     noop: noop,
                     lookup: lookup)
}

private func waitForMainQueue() {
    let mainQueueProcessed = XCTestExpectation(description: "Main queue processed")
    DispatchQueue.main.async {
        mainQueueProcessed.fulfill()
    }
    XCTAssertEqual(XCTWaiter().wait(for: [mainQueueProcessed], timeout: 1), .completed)
}

private extension LookUpResult {
    static func stub(version: String?, releaseNotes: String? = nil) -> LookUpResult {
        LookUpResult(artistId: nil,
                     artistName: nil,
                     artistViewUrl: nil,
                     artworkUrl100: nil,
                     artworkUrl512: nil,
                     artworkUrl60: nil,
                     averageUserRating: nil,
                     averageUserRatingForCurrentVersion: nil,
                     bundleId: nil,
                     contentAdvisoryRating: nil,
                     currency: nil,
                     currentVersionReleaseDate: nil,
                     description: nil,
                     fileSizeBytes: nil,
                     formattedPrice: nil,
                     genreIds: nil,
                     genres: nil,
                     isVppDeviceBasedLicensingEnabled: nil,
                     kind: nil,
                     languageCodesISO2A: nil,
                     minimumOsVersion: nil,
                     price: nil,
                     primaryGenreId: nil,
                     primaryGenreName: nil,
                     releaseDate: nil,
                     releaseNotes: releaseNotes,
                     screenshotUrls: nil,
                     sellerName: nil,
                     sellerUrl: nil,
                     trackCensoredName: nil,
                     trackContentRating: nil,
                     trackId: nil,
                     trackName: nil,
                     trackViewUrl: nil,
                     userRatingCount: nil,
                     userRatingCountForCurrentVersion: nil,
                     version: version,
                     wrapperType: nil)
    }
}
