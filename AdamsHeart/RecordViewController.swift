//
//  RecordViewController.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/4/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import UIKit

class RecordViewController: UIViewController, HeartRateDelegate {
    private var heartRateData: HeartRateData?
    @IBOutlet weak var statusLabel: UILabel?
    @IBOutlet weak var hrLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func loadView() {
        super.loadView()
        let hrChartRect = CGRect(x: 5.0, y: 100.0, width: self.view.frame.width - 10.0, height: 300.0)
        let session = Session.startOrCurrent()
        session.delegate = self
        let data = session.data
        let startObs = Double(max(0, data.curObservation - 59))
        let hrChart = HeartRateChart(
            frame: hrChartRect, data: data, type: .record,
            startObs: startObs, numObs: 60.0)
        self.view.addSubview(hrChart)
        if session.status != nil {
            statusLabel?.text = session.status
        }
    }
    
    func heartRateServiceDidConnect(name: String) {
        statusLabel?.text = name
    }

    func heartRateServiceDidDisconnect() {
        
    }
    
    func heartRateDataArrived(data: HeartRateDataPoint) {
        hrLabel?.text = String(data.hr)
    }
}
