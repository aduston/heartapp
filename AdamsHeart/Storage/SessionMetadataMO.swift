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
    @NSManaged var maxHR: NSNumber?
    @NSManaged var halvedCount: NSNumber?
    
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
    
    var maxHRValue: UInt8? {
        get {
            return maxHR?.uint8Value
        }
        set {
            maxHR = NSNumber(value: newValue!)
        }
    }
    
    var halvedCountValue: UInt32? {
        get {
            return halvedCount?.uint32Value
        }
        set {
            halvedCount = NSNumber(value: newValue!)
        }
    }
}
