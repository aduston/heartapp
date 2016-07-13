//
//  SessionMetadataTests.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/13/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import XCTest
@testable import AdamsHeart

class SessionMetadataTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSerialization() {
        let sm = SessionMetadata(version: 1)
        let data = sm.toJson()!
        let newSM = SessionMetadata.fromJson(json: data)
        XCTAssertEqual(1, newSM!.version)
    }
}
