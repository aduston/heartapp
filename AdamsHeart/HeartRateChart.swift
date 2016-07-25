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
    private var chartRect: CGRect
    private var touchState: TouchState?
    
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
        self.chartRect = ChartParams.graphRect(viewRect: frame);
        super.init(frame: frame)
        self.isMultipleTouchEnabled = true
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
        if data.curObservation + 1 > Int(numObs) {
            self.startObs += 1.0
        }
        self.setNeedsDisplay()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touchState == nil {
            touchState = TouchState.newState(touches: touches, startObs: startObs, numObs: numObs, view: self, chartRect: chartRect)
        } else {
            touchState = touchState!.newState(afterAdding: touches)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touchState != nil {
            let (newStartObs, newNumObs) = touchState!.curStartAndNumObs()
            numObs = min(Double(data.curObservation + 1), max(0.0, newNumObs))
            if type == .record {
                startObs = Double(data.curObservation) - numObs + 1
            } else {
                startObs = min(Double(data.curObservation + 1) - numObs, max(0.0, newStartObs))
            }
            self.setNeedsDisplay()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touchState == nil {
            touchState = TouchState.newState(touches: touches, startObs: startObs, numObs: numObs, view: self, chartRect: chartRect)
        } else {
            touchState = touchState?.newState(afterRemoving: touches)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // TODO: what?
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        chartDrawer.draw(context: UIGraphicsGetCurrentContext()!, rect: rect, startObs: startObs, numObs: numObs)
    }
}
