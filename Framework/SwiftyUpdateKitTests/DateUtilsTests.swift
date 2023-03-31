//
//  DateUtilsTests.swift
//  SwiftyUpdateKitTests
//
//  Created by Masaki Ando on 2023/03/31.
//  Copyright © 2023 Hituzi Ando. All rights reserved.
//

import XCTest
@testable import SwiftyUpdateKit

final class DateUtilsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCurrentDate() throws {
        Locale.availableIdentifiers.forEach { id in
            let dateInt = DateUtils.currentDate(locale: Locale(identifier: id))
            XCTAssertNotNil(dateInt)
        }
    }
}
