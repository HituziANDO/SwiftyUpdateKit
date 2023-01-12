//
//  SwiftyUpdateKitTests.swift
//  SwiftyUpdateKitTests
//
//  Copyright © 2021 Hituzi Ando. All rights reserved.
//

import XCTest
@testable import SwiftyUpdateKit

class SwiftyUpdateKitTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testVersion() throws {
        XCTAssertNotNil(SUK.version)
    }

    func testReset() throws {
        // Set test data.
        let ud = UserDefaults.standard
        ud.set(Utility.currentDate(), forKey: SwiftyUpdateKitLastVersionCheckDateKey)
        ud.set(Utility.currentDate(), forKey: SwiftyUpdateKitLastRequireReviewDateKey)
        ReleaseNotes.update("1.2.2", forUserID: "Test")

        SUK.reset()

        XCTAssertEqual(0, ud.integer(forKey: SwiftyUpdateKitLastVersionCheckDateKey))
        XCTAssertEqual(0, ud.integer(forKey: SwiftyUpdateKitLastRequireReviewDateKey))
        XCTAssertNil(ud.string(forKey: SwiftyUpdateKitLatestAppVersionKey))
    }
}
