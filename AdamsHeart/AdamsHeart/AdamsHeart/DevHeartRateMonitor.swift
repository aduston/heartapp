//
//  DevHeartRateMonitor.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/4/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation

class DevHeartRateMonitor: HeartRateMonitor {
    private var delegate: HeartRateDelegate
    private var timer: Timer?
    private var fireNo: UInt16;
    
    init(delegate: HeartRateDelegate) {
        self.delegate = delegate;
        self.fireNo = 0;
    }
    
    func start() {
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
    }
    
    @objc func timerFired() {
        if fireNo == 0 {
            self.delegate.heartRateServiceDidConnect(name: "polar strap")
        } else {
            self.delegate.heartRateDataArrived(data: HeartRateDataPoint(
                hr: 80 + (fireNo * 3) % 80,
                sensorContact: 0,
                energy: 0,
                rrInterval: 89
            ))
        }
        fireNo += 1
    }
    
    func stop() {
        self.timer?.invalidate()
    }
}
