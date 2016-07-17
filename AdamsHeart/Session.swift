//
//  Session.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/12/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation

// Beacuse Sessions are maintained even when the app is in the 
// background, this can't be tied to any particular UIView.
class Session: HeartRateDelegate {
    private static var instance: Session?
    
    static func startOrCurrent() -> Session {
        if instance == nil {
            instance = Session()
        }
        return instance!
    }
    
    static func stop() -> Session? {
        instance?.stop()
        let existingInstance = instance
        instance = nil
        return existingInstance
    }
    
    private var _data: HeartRateData
    private var _monitor: HeartRateMonitor?
    private var _sessionStart: UInt32?
    private var _status: String?
    private var _delegate: HeartRateDelegate?
    
    init() {
        #if (arch(i386) || arch(x86_64))
            // let numSecondsRun = 110
            // _data = HeartRateData(withStartTime: NSDate.timeIntervalSinceReferenceDate() - Double(numSecondsRun))
            // for i in 0..<numSecondsRun {
            //     _data.addObservation(heartRate: UInt8(80 + (i % 40)), elapsedSeconds: i)
            // }
            _data = HeartRateData()
            _monitor = DevHeartRateMonitor(delegate: self)
        #else
            _data = HeartRateData()
            _monitor = BLEHeartRateMonitor(delegate: self)
        #endif
        _monitor!.start()
    }
    
    func heartRateServiceDidConnect(name: String) {
        _status = name
        if _delegate != nil {
            _delegate!.heartRateServiceDidConnect(name: name)
        }
    }
    
    func heartRateServiceDidDisconnect() {
        if _delegate != nil {
            _delegate!.heartRateServiceDidDisconnect()
        }
    }
    
    func heartRateDataArrived(data: HeartRateDataPoint) {
        if _sessionStart == nil {
            _sessionStart = UInt32(Date().timeIntervalSinceReferenceDate)
        }
        _data.addObservation(heartRate: UInt8(data.calculatedHR))
        if _delegate != nil {
            _delegate!.heartRateDataArrived(data: data)
        }
    }
    
    func bluetoothTurnedOff() {
        if _delegate != nil {
            _delegate!.bluetoothTurnedOff()
        }
    }
    
    func connectionUpdate(_ status: String) {
        _status = status
        if _delegate != nil {
            _delegate?.connectionUpdate(status)
        }
    }
    
    func stop() {
        _monitor!.stop()
    }
    
    var recordedObservations: [Observation] {
        var recorded = [Observation](repeating: 0, count: data.curObservation + 1)
        for i in 0...data.curObservation {
            recorded[i] = data.observations[i]
        }
        return recorded
    }
    
    var status: String? {
        return _status
    }
    
    var sessionStart: UInt32? {
        return _sessionStart
    }

    var delegate: HeartRateDelegate? {
        get {
            return _delegate
        }
        set {
            _delegate = newValue
        }
    }
    
    var data: HeartRateData {
        return _data
    }
}
