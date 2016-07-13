//
//  HeartRateDataTests.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/10/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import XCTest
@testable import AdamsHeart

class HeartRateDataTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testComponents() {
        let data = HeartRateData()
        data.addObservation(heartRate: 180, elapsedSeconds: 72014)
        var (seconds, halved, heartRate) = HeartRateData.components(observation: data.observations[0])
        XCTAssertEqual(72014, seconds)
        XCTAssertEqual(false, halved)
        XCTAssertEqual(180, heartRate)
        
        data.addObservation(heartRate: 90, elapsedSeconds: 72015)
        (seconds, halved, heartRate) = HeartRateData.components(observation: data.observations[1])
        XCTAssertEqual(72015, seconds)
        XCTAssertEqual(true, halved)
        XCTAssertEqual(90, heartRate)
    }
    
    func testAdd() {
        let data = HeartRateData()
        for i in 0...500 {
            let val = 80 + (i % 90)
            data.addObservation(heartRate: UInt8(val), elapsedSeconds: i)
        }
        XCTAssertEqual(500, data.curObservation)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
