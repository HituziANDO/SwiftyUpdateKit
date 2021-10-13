//
//  ReleaseNotesTests.swift
//  SwiftyUpdateKitTests
//
//  Created by Masaki Ando on 2021/10/12.
//  Copyright © 2021 Hituzi Ando. All rights reserved.
//

import XCTest
@testable import SwiftyUpdateKit

class ReleaseNotesTests: XCTestCase {

    override func setUpWithError() throws {
        SUK.reset()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFirstUpdated() throws {
        let userID = "Test"

        guard let appVersion = ReleaseNotes.first(forUserID: userID).latest else {
            // First updated.
            XCTAssertNil(ReleaseNotes.first(forUserID: userID).latest)
            return
        }

        XCTFail()
    }

    func testUpdate() throws {
        let userID = "Test"
        let storeVersion = "1.2.3"

        // Set current version.
        ReleaseNotes.update("1.2.2", forUserID: userID)

        guard let appVersion = ReleaseNotes.first(forUserID: userID).latest else {
            XCTFail()
            return
        }

        let versionCompare = VersionCompare()
        guard versionCompare.compare(storeVersion, with: appVersion) else {
            // Saved app version is already latest.
            XCTFail()
            return
        }

        XCTAssertEqual(appVersion, "1.2.2")

        ReleaseNotes.update(storeVersion, forUserID: userID)

        XCTAssertEqual(ReleaseNotes.first(forUserID: userID).latest, "1.2.3")
    }

    func testAlreadyLatest() throws {
        let userID = "Test"
        let storeVersion = "1.2.3"

        // Set current version.
        ReleaseNotes.update("1.2.3", forUserID: userID)

        guard let appVersion = ReleaseNotes.first(forUserID: userID).latest else {
            XCTFail()
            return
        }

        let versionCompare = VersionCompare()
        guard versionCompare.compare(storeVersion, with: appVersion) else {
            // Saved app version is already latest.
            XCTAssertEqual(appVersion, "1.2.3")
            return
        }

        XCTFail()
    }

    func testAnotherUser() throws {
        ReleaseNotes.update("1.2.3", forUserID: "Test1")
        XCTAssertEqual(ReleaseNotes.first(forUserID: "Test1").latest, "1.2.3")
        XCTAssertEqual(ReleaseNotes.first(forUserID: "Test1").userID, "Test1")

        XCTAssertNil(ReleaseNotes.first(forUserID: "Test2").latest)
        XCTAssertEqual(ReleaseNotes.first(forUserID: "Test2").userID, "Test2")
    }
}
