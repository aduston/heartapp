//
//  HeartRateData.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/4/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation

struct HeartRateDataPoint {
    var hr: UInt16
    var sensorContact: UInt8
    var energy: UInt16
    var rrInterval: UInt16
}
