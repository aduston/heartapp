//
//  RecordViewController.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/4/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import UIKit

class RecordViewController: UIViewController, HeartRateDelegate {
    private var heartRateMonitor: HeartRateMonitor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.heartRateMonitor = BLEHeartRateMonitor(delegate: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func heartRateServiceDidConnect(name: String) {
        
    }

    func heartRateServiceDidDisconnect() {
        
    }
    
    func heartRateDataArrived(data: HeartRateData) {
        
    }
}
