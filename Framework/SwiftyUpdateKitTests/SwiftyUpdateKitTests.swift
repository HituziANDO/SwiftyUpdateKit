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

final class SchedulingConditionTests: XCTestCase {
    func testDailyVersionCheckRecordsOnlyAfterSuccess() {
        let clock = TestClock(currentDate: 20_260_819)
        let stateStore = TestSchedulingStateStore()
        let condition = VersionCheckConditionDaily(clock: clock, stateStore: stateStore)

        XCTAssertTrue(condition.shouldCheckVersion())
        XCTAssertTrue(condition.shouldCheckVersion())
        XCTAssertEqual(stateStore.writeCount, 0)

        condition.recordSuccessfulVersionCheck()
        condition.recordSuccessfulVersionCheck()

        XCTAssertEqual(stateStore.writeCount, 1)
        XCTAssertEqual(stateStore.integer(forKey: SwiftyUpdateKitLastVersionCheckDateKey),
                       20_260_819)
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
        XCTAssertEqual(stateStore.integer(forKey: SwiftyUpdateKitLastVersionCheckDateKey),
                       20_260_819)
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
        initializeSUKForSchedulingTests()

        checkVersion(firstCondition, lookup: lookup)
        checkVersion(secondCondition, lookup: lookup)
        waitForMainQueue()

        XCTAssertEqual(lookup.requestCount, 1)
        XCTAssertEqual(stateStore.writeCount, 0)

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
        var requestCount = 0

        XCTAssertTrue(condition.shouldRequestReview())
        XCTAssertEqual(stateStore.writeCount, 0)

        SUK.requestReviewIfNeeded(condition) {
            requestCount += 1
            XCTAssertEqual(stateStore.writeCount, 1)
        }

        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(stateStore.integer(forKey: SwiftyUpdateKitLastRequireReviewDateKey),
                       20_260_819)
        XCTAssertFalse(condition.shouldRequestReview())
    }

    func testSkipFirstDayRecordsInitializationSeparatelyFromRequestAttempt() {
        let clock = TestClock(currentDate: 20_260_819)
        let stateStore = TestSchedulingStateStore()
        let condition = RequestReviewConditionDailySkipFirstDay(clock: clock,
                                                                stateStore: stateStore)
        var requestCount = 0

        SUK.requestReviewIfNeeded(condition) {
            requestCount += 1
        }

        XCTAssertEqual(requestCount, 0)
        XCTAssertEqual(stateStore.writeCount, 1)
        XCTAssertEqual(stateStore.integer(forKey: SwiftyUpdateKitLastRequireReviewDateKey),
                       20_260_819)

        clock.date = 20_260_820
        SUK.requestReviewIfNeeded(condition) {
            requestCount += 1
        }

        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(stateStore.writeCount, 2)
        XCTAssertEqual(stateStore.integer(forKey: SwiftyUpdateKitLastRequireReviewDateKey),
                       20_260_820)
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

    func set(_ value: Int, forKey key: String) {
        values[key] = value
        writeCount += 1
    }

    func integer(forKey key: String) -> Int {
        values[key] ?? 0
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

private func initializeSUKForSchedulingTests() {
    SUK.initialize(withConfig: SwiftyUpdateKitConfig(version: "1.0.0",
                                                     iTunesID: "1234567890",
                                                     storeURL: "https://apps.apple.com/app/id1234567890"))
}

private func checkVersion(_ condition: VersionCheckCondition,
                          lookup: AppStoreLookup)
{
    SUK.checkVersion(condition,
                     update: nil,
                     newRelease: { _, _, _ in },
                     forUserID: "Test",
                     noop: nil,
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
