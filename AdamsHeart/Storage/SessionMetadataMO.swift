//
//  SessionMetadataMO.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/14/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation
import CoreData

class SessionMetadataMO: NSManagedObject {
    @NSManaged var timestampAtt: NSNumber
    @NSManaged var onServerAtt: NSNumber
    
    var timestamp: UInt32 {
        get {
            return timestampAtt.uint32Value
        }
        set {
            timestampAtt = NSNumber(value: newValue)
        }
    }
    
    var onServer: Bool {
        get {
            return onServerAtt.boolValue
        }
        set {
            onServerAtt = NSNumber(booleanLiteral: newValue)
        }
    }
}
