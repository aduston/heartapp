//
//  HeartRateData.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/4/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation

public typealias Observation = UInt32

public class HeartRateData {
    public var observations: [Observation]
    public var curObservation: Int
    private var startTime: TimeInterval = 0

    init() {
        self.observations = [Observation](repeating: 0, count: 60 * 60 * 24)
        self.curObservation = -1
    }

    public func addObservation(heartRate: UInt8) {
        if curObservation == -1 {
            startTime = NSDate.timeIntervalSinceReferenceDate()
        }
        let elapsedSeconds = Int(NSDate.timeIntervalSinceReferenceDate() - startTime)
        let minutes = UInt16(elapsedSeconds / 60)
        let seconds = UInt8(elapsedSeconds % 60)
        observations[Int(curObservation + 1)] = makeObservation(
            minutes: minutes, seconds: seconds,
            halved: isHalved(heartRate: heartRate), heartRate: heartRate)
        curObservation += 1
    }
    
    private func isHalved(heartRate: UInt8) -> Bool {
        if curObservation == -1 {
            return false
        } else {
            let lastObs = HeartRateData.components(observation: observations[curObservation])
            if lastObs.halved {
                return heartRate < 90
            } else {
                return heartRate <= lastObs.heartRate * 3 / 5
            }
        }
    }

    private func makeObservation(minutes: UInt16, seconds: UInt8, halved: Bool, heartRate: UInt8) -> Observation {
        var obs = (UInt32(minutes) << 16) & (UInt32(seconds) << 8) & UInt32(heartRate)
        if halved {
            obs |= (0x1 << 15)
        }
        return Observation(obs)
    }
    
    public static func components(observation: Observation) -> (minutes: UInt16, seconds: UInt8, halved: Bool, heartRate: UInt8) {
        let minutes = UInt16(observation >> 16)
        let seconds = UInt8((observation >> 8) & 0x7F)
        let halved = ((observation >> 8) & 0x80) != 0
        let heartRate = UInt8(observation & 0xFF)
        return (minutes, seconds, halved, heartRate)
    }
}
