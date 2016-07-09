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
    private var heartRateData: HeartRateData?
    @IBOutlet weak var statusLabel: UILabel?
    @IBOutlet weak var hrLabel: UILabel?
    @IBOutlet weak var hrChart: HeartRateChart?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        heartRateData = HeartRateData()
        #if (arch(i386) || arch(x86_64))
            self.heartRateMonitor = DevHeartRateMonitor(delegate: self)
        #else
            self.heartRateMonitor = BLEHeartRateMonitor(delegate: self)
        #endif
        self.heartRateMonitor!.start()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func heartRateServiceDidConnect(name: String) {
        statusLabel?.text = name
    }

    func heartRateServiceDidDisconnect() {
        
    }
    
    func heartRateDataArrived(data: HeartRateDataPoint) {
        hrLabel?.text = String(data.hr)
        heartRateData?.addObservation(heartRate: data.hr)
        
    }
}
