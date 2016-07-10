//
//  ChartDrawer.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/9/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation
import CoreGraphics

public class ChartDrawer {
    private var data : HeartRateData
    
    init(data: HeartRateData) {
        self.data = data
    }
    
    public func draw(context: CGContext, rect: CGRect, startObs: Double, numObs: Double) {
        context.setStrokeColor(red: 0.5, green: 0.3, blue: 0.2, alpha: 0.5)
        context.setLineWidth(10.0)
        context.moveTo(x: 0, y: 0)
        context.addLineTo(x: 200, y: 200)
        context.strokePath()
    }
}
