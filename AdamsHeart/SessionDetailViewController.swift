//
//  SessionDetailViewController.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/19/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation
import UIKit

class SessionDetailViewController: UIViewController {
    var sessionMetadata: SessionMetadataMO?
    var heartData: HeartRateData?
    
    override func loadView() {
        super.loadView()
        let hrChartRect = CGRect(
            x: 5.0,
            y: (self.view.frame.height - 300.0) / 2.0,
            width: self.view.frame.width - 10.0, height: 300.0)
        let hrChart = HeartRateChart(
            frame: hrChartRect, data: heartData!, type: .view,
           startObs: 0.0, numObs: Double(heartData!.curObservation + 1))
        self.view.addSubview(hrChart)
    }
    
    @IBAction func closeClicked(sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
