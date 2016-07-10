//
//  ChartDrawer.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/9/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation
import CoreGraphics

#if os(iOS)
    import UIKit

    typealias NSUIFont = UIFont
#elseif os(OSX)
    import Cocoa
    
    typealias NSUIFont = NSFont
#endif

struct ChartParams {
    let context: CGContext
    let rect: CGRect
    let startObs: Double
    let numObs: Double
    let minRate: UInt8
    let maxRate: UInt8
    let spaceLeft: CGFloat = 30
    let spaceBottom: CGFloat = 20
    let minBeatHeight: CGFloat = 5
    let labelFont = NSUIFont(name: "Helvetica", size: 14)!
    
    var graphRect: CGRect {
        return CGRect(origin: CGPoint(x: rect.minX + spaceLeft,
                                      y: rect.minY + spaceBottom),
                      size: CGSize(width: rect.width - spaceLeft,
                                   height: rect.height - spaceBottom))
    }
    var beatHeight: CGFloat {
        if maxRate == minRate {
            return 0
        } else {
            return (graphRect.size.height - minBeatHeight) / CGFloat(maxRate - minRate)
        }
    }
    
    var spread: UInt8 {
        return maxRate - minRate
    }
}

public class ChartDrawer {
    private var data : HeartRateData
    
    init(data: HeartRateData) {
        self.data = data
    }
    
    public func draw(context: CGContext, rect: CGRect, startObs: Double, numObs: Double) {
        let (minHR, maxHR) = data.minAndMax(startObs: Int(startObs), numObs: Int(numObs))
        let params = ChartParams(
            context: context, rect: rect, startObs: startObs,
            numObs: numObs, minRate: minHR, maxRate: maxHR)
        drawBackground(params)
        drawHorizontalLines(params)
        drawValues(params)
        drawTimes(params)
    }
    
    private func drawBackground(_ params: ChartParams) {
        params.context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        params.context.fill(params.rect)
    }
    
    private func drawHorizontalLines(_ params: ChartParams) {
        let c = params.context
        c.setLineWidth(1.0)
        for hr in params.minRate...params.maxRate {
            if params.spread > 40 && hr % 5 != 0 {
                continue
            }
            let labeledLine = (params.spread < 60 && hr % 5 == 0) || hr % 10 == 0
            let y = params.graphRect.minY + params.minBeatHeight + CGFloat(hr - params.minRate) * params.beatHeight
            let strokeDarkness: CGFloat = labeledLine ? 0.0 : 0.6
            c.setStrokeColor(red: strokeDarkness, green: strokeDarkness, blue: strokeDarkness, alpha: 1.0)
            c.moveTo(x: params.graphRect.minX, y: y)
            c.addLineTo(x: params.graphRect.maxX, y: y)
            c.strokePath()
            if labeledLine {
                addHRLabel(params: params, hr: hr, y: y)
            }
        }
    }
    
    private func addHRLabel(params: ChartParams, hr: UInt8, y: CGFloat) {
        let label = String(hr) as NSString
        #if os(iOS)
        let labelSize = label.size(attributes: [NSFontAttributeName: params.labelFont])
        #elseif os(OSX)
        let labelSize = label.size(withAttributes: [NSFontAttributeName: params.labelFont])
        #endif
        let point = CGPoint(x: params.graphRect.minX - 2 - labelSize.width,
                            y: y - (labelSize.height / 2.0))
        label.draw(at: point, withAttributes: [NSFontAttributeName: params.labelFont])
    }
    
    private func drawValues(_ params: ChartParams) {
        
    }
    
    private func drawTimes(_ params: ChartParams) {
        
    }
}
