//
//  HeartRateData.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/4/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

class HeartRateData {
    private var heartBeats: [UInt16]
    private var curObservation: Int32

    init() {
        self.heartBeats = [UInt16](repeating: 0, count: 60 * 60 * 24)
        self.curObservation = -1
    }

    public func addObservation(heartRate: UInt16) {
        heartBeats[curObservation + 1] = heartRate
        curObservation += 1
    }
}
