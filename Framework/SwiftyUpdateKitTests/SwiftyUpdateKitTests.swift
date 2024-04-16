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
