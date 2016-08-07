//
//  SessionMetadataMO.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/14/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation
import CoreData

@objc(SessionMetadataMO)
class SessionMetadataMO: NSManagedObject {
    @NSManaged var timestamp: NSNumber
    @NSManaged var onServer: NSNumber
    @NSManaged var meanHRThreshold: NSNumber?
    @NSManaged var minHRThreshold: NSNumber?
    @NSManaged var maxHRThreshold: NSNumber?
    @NSManaged var numHRThreshold: NSNumber?
    
    var timestampValue: UInt32 {
        get {
            return timestamp.uint32Value
        }
        set {
            timestamp = NSNumber(value: newValue)
        }
    }
    
    var onServerValue: Bool {
        get {
            return onServer.boolValue
        }
        set {
            onServer = NSNumber(booleanLiteral: newValue)
        }
    }

    var thresholdStats: ThresholdStats? {
        get {
            if meanHRThreshold == nil {
                return nil
            } else {
                return ThresholdStats(
                    mean: (meanHRThreshold?.uint8Value)!,
                    min: (minHRThreshold?.uint8Value)!,
                    max: (maxHRThreshold?.uint8Value)!,
                    num: (numHRThreshold?.intValue)!)
            }
        }
        set {
            guard newValue != nil else {
                return
            }
            meanHRThreshold = NSNumber(value: newValue!.mean)
            minHRThreshold = NSNumber(value: newValue!.min)
            maxHRThreshold = NSNumber(value: newValue!.max)
            numHRThreshold = NSNumber(value: newValue!.num)
        }
    }
}
