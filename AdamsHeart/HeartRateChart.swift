//
//  HeartRateChart.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/4/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation
import UIKit

enum ChartType {
    case record, view
}

class HeartRateChart: UIView, UIGestureRecognizerDelegate {
    private var data: HeartRateData
    private var type: ChartType
    private var startObs: Double
    private var numObs: Double
    private var chartDrawer: ChartDrawer
    private let pinchRec = UIPinchGestureRecognizer()
    private var pinchStartNumObs: Double?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(frame: CGRect, data: HeartRateData, type: ChartType) {
        self.init(frame: frame, data: data, type: type, startObs: 0.0, numObs: 0.0)
    }
    
    init(frame: CGRect, data: HeartRateData, type: ChartType, startObs: Double, numObs: Double) {
        self.data = data
        self.type = type
        self.startObs = startObs
        self.numObs = numObs
        self.chartDrawer = ChartDrawer(data: data)
        super.init(frame: frame)
        self.isMultipleTouchEnabled = true
        self.pinchRec.addTarget(self, action: #selector(pinchedView))
        self.addGestureRecognizer(self.pinchRec)
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if self.type == .record {
            if newSuperview == nil {
                data.setAddObservationHandler(handler: nil)
            } else {
                data.setAddObservationHandler(handler: {
                    self.newObservation()
                })
            }
        }
    }
    
    private func newObservation() {
        self.startObs += 1.0
        self.setNeedsDisplay()
    }

    @objc private func pinchedView(sender: UIPinchGestureRecognizer) {
        if sender.numberOfTouches() != 2 {
            return
        }
        let state = sender.state
        let scale = sender.scale
        if state == .began {
            pinchStartNumObs = numObs
        } else if state == .ended {
            pinchStartNumObs = nil
        }
        if pinchStartNumObs == nil {
            return
        }
        // let velocity = sender.velocity
        numObs = min(Double(data.curObservation + 1), max(0.0, pinchStartNumObs! * Double(1.0 / scale)))
        if type == .record {
            startObs = Double(data.curObservation) - numObs + 1.0
        }
        self.setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        chartDrawer.draw(context: UIGraphicsGetCurrentContext()!, rect: rect, startObs: startObs, numObs: numObs)
    }
}