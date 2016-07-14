//
//  HeartRateData.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/4/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation

public typealias Observation = UInt32
public typealias AddObservationHandler = () -> ()

public class HeartRateData {
    public var observations: [Observation]
    public var curObservation: Int
    private var isLocked: Bool = false
    private var startTime: TimeInterval = 0
    private var addObservationHandler: AddObservationHandler?

    init() {
        self.observations = [Observation](repeating: 0, count: 60 * 60 * 24)
        self.curObservation = -1
    }
    
    init(observations: [Observation]) {
        self.observations = observations
        self.curObservation = self.observations.count - 1
        self.isLocked = true
    }
    
    init(withStartTime startTime:TimeInterval) {
        // used for dev only
        self.observations = [Observation](repeating: 0, count: 60 * 60 * 24)
        self.curObservation = -1
        self.startTime = startTime
    }

    public func addObservation(heartRate: UInt8) {
        if curObservation == -1 {
            startTime = NSDate.timeIntervalSinceReferenceDate()
        }
        let elapsedSeconds = Int(NSDate.timeIntervalSinceReferenceDate() - startTime)
        addObservation(heartRate: heartRate, elapsedSeconds: elapsedSeconds)
    }
    
    public func addObservation(heartRate: UInt8, elapsedSeconds: Int) {
        if isLocked {
            // TODO: fatal
            return
        }
        observations[Int(curObservation + 1)] = makeObservation(
            seconds: UInt32(elapsedSeconds), halved: isHalved(heartRate: heartRate), heartRate: heartRate)
        curObservation += 1
        if addObservationHandler != nil {
            addObservationHandler!();
        }
    }
    
    public func setAddObservationHandler(handler: AddObservationHandler?) {
        self.addObservationHandler = handler
    }
    
    private func isHalved(heartRate: UInt8) -> Bool {
        if curObservation == -1 {
            return false
        } else {
            let lastObs = HeartRateData.components(observation: observations[curObservation])
            if lastObs.halved {
                return heartRate < 90
            } else {
                return heartRate <= lastObs.heartRate / 5 * 3
            }
        }
    }

    private func makeObservation(seconds: UInt32, halved: Bool, heartRate: UInt8) -> Observation {
        var obs = (seconds << 8) | UInt32(heartRate)
        if halved {
            obs |= (0x1 << 31)
        }
        return Observation(obs)
    }
    
    public static func components(observation: Observation) -> (seconds: UInt32, halved: Bool, heartRate: UInt8) {
        let seconds = UInt32((observation >> 8) & ~(1 << 23))
        let halved = (observation >> 31) != 0
        let heartRate = UInt8(observation & 0xFF)
        return (seconds, halved, heartRate)
    }
    
    public func minAndMax(startObs: Int, numObs: Int) -> (minHR: UInt8, maxHR: UInt8) {
        let startIndex = max(startObs, 0)
        let endIndex = min(startObs + numObs, curObservation + 1)
        var minHR: UInt8 = 200, maxHR: UInt8 = 0
        for index in startIndex..<endIndex {
            let heartRate = UInt8(observations[index] & 0xFF)
            if heartRate < minHR {
                minHR = heartRate
            }
            if heartRate > maxHR {
                maxHR = heartRate
            }
        }
        return (minHR, maxHR)
    }
    
    public func summary(startObs: Double, endObs: Double) -> (minHR: UInt8, maxHR: UInt8, hasHalved: Bool) {
        let minIndex = max(Int(startObs), 0)
        let maxIndex = min(Int(ceil(endObs)), curObservation)
        var minHR: UInt8 = 200
        var maxHR: UInt8 = 0
        var hasHalved = false
        for i in minIndex...maxIndex {
            let (_, halved, hr) = HeartRateData.components(observation: observations[i])
            if halved {
                hasHalved = true
            }
            if hr < minHR {
                minHR = hr
            }
            if hr > maxHR {
                maxHR = hr
            }
        }
        return (minHR, maxHR, hasHalved)
    }
    
    public static func observationsToData(observations: [Observation]) -> Data {
        var bytes = [UInt8](repeating: 0, count: observations.count * 4)
        for i in 0..<observations.count {
            copyBytes(source: observations[i], destination: &bytes, offset: i * 4)
        }
        return Data(bytes: bytes)
    }
    
    public static func dataToObservations(data: Data) -> [Observation] {
        var bytes: [UInt8] = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &bytes, count: data.count)
        var observations = [UInt32](repeating: 0, count: data.count / 4)
        for i in 0..<bytes.count {
            observations[i] = makeInt(bytes: &bytes, offset: i / 4)
        }
        return observations
    }
}
