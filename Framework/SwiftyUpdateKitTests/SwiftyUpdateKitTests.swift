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
        XCTAssertNotNil(SwiftyUpdateKit.version)
    }
}
