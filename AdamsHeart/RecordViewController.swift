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
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    override func loadView() {
        super.loadView()
        #if (arch(i386) || arch(x86_64))
            let numSecondsRun = 110
            self.heartRateData = HeartRateData(withStartTime: NSDate.timeIntervalSinceReferenceDate() - Double(numSecondsRun))
            for i in 0..<numSecondsRun {
                heartRateData?.addObservation(heartRate: UInt8(80 + (i % 40)), elapsedSeconds: i)
            }
        #else
            self.heartRateData = HeartRateData()
        #endif
        let hrChartRect = CGRect(x: 5.0, y: 100.0, width: self.view.frame.width - 10.0, height: 300.0)
        let startObs = Double(max(0, heartRateData!.curObservation - 59))
        let hrChart = HeartRateChart(frame: hrChartRect, data: heartRateData!, type: .record,
                                     startObs: startObs, numObs: 60.0)
        self.view.addSubview(hrChart)
    }
    
    func heartRateServiceDidConnect(name: String) {
        statusLabel?.text = name
    }

    func heartRateServiceDidDisconnect() {
        
    }
    
    func heartRateDataArrived(data: HeartRateDataPoint) {
        hrLabel?.text = String(data.hr)
        heartRateData!.addObservation(heartRate: UInt8(data.hr))
    }
}
