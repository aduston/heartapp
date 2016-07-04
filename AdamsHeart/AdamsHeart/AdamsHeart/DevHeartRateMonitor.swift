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
    
    init(delegate: HeartRateDelegate) {
        self.delegate = delegate;
    }
    
    func start() {
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
    }
    
    @objc func timerFired() {
        
    }
    
    func stop() {
        self.timer?.invalidate()
    }
}
