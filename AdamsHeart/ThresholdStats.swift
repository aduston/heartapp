//
//  ThresholdStats.swift
//  AdamsHeart
//
//  Created by Adam Duston on 8/7/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation

/**
 Define a threshold heart rate (thr) as hr immediately before a 2:1 drop.
 For a given recording session, ThresholdStats contains mean thr, 
 the number of thr observations, plus min and max (clamped within 3 stdevs  of mean)
 */
struct ThresholdStats {
    let mean: UInt8
    let min: UInt8
    let max: UInt8
    let num: Int
}
