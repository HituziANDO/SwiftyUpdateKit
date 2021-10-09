//
//  VersionCompareTests.swift
//  SwiftyUpdateKitTests
//
//  Created by Masaki Ando on 2021/10/09.
//  Copyright © 2021 Hituzi Ando. All rights reserved.
//

import XCTest
@testable import SwiftyUpdateKit

class VersionCompareTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCompare_1_3_2_vs_1_3_1() throws {
        let storeVer = "1.3.2"
        let currentVer = "1.3.1"
        XCTAssertTrue(VersionCompare().compare(storeVer, with: currentVer))
    }

    func testCompare_1_3_vs_1_3() throws {
        let storeVer = "1.3"
        let currentVer = "1.3"
        XCTAssertFalse(VersionCompare().compare(storeVer, with: currentVer))
    }

    func testCompare_1_3_21_vs_1_4_2() throws {
        let storeVer = "1.3.21"
        let currentVer = "1.4.2"
        XCTAssertFalse(VersionCompare().compare(storeVer, with: currentVer))
    }

    func testCompare_2_3_vs_1_6_20211009() throws {
        let storeVer = "2.3"
        let currentVer = "1.6.20211009"
        XCTAssertTrue(VersionCompare().compare(storeVer, with: currentVer))
    }

    func testCompare_0_4_20210909_vs_0_3_20211005() throws {
        let storeVer = "0.4.20210909"
        let currentVer = "0.3.20211005"
        XCTAssertTrue(VersionCompare().compare(storeVer, with: currentVer))
    }
}
