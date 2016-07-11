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
    let labelFont = NSUIFont(name: "Helvetica", size: 14)!
    let regularBeatColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components:[0.0, 0.0, 1.0, 1.0])!
    let halvedBeatColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components:[1.0, 0.0, 0.0, 1.0])!
    
    var graphRect: CGRect {
        // TODO: save after first calculation?
        return CGRect(origin: CGPoint(x: rect.minX + spaceLeft,
                                      y: rect.minY + spaceBottom),
                      size: CGSize(width: rect.width - spaceLeft,
                                   height: rect.height - spaceBottom))
    }
    var beatHeight: CGFloat {
        // TODO:  save after first calculation?
        if maxRate == minRate {
            return 0
        } else {
            return graphRect.size.height / CGFloat(maxRate - minRate)
        }
    }
    
    var spread: UInt8 {
        return maxRate - minRate
    }
    
    var barWidth: CGFloat {
        // TODO: save after first
        return graphRect.width / CGFloat(numObs)
    }

    func yForHR(_ hr: UInt8) -> CGFloat {
        // TODO: save after first
        return graphRect.minY + CGFloat(hr - minRate) * beatHeight
    }
}

public class ChartDrawer {
    private var data : HeartRateData
    
    init(data: HeartRateData) {
        self.data = data
    }
    
    public func draw(context: CGContext, rect: CGRect, startObs: Double, numObs: Double) {
        let (actualMinHR, actualMaxHR) = data.minAndMax(startObs: Int(startObs), numObs: Int(numObs))
        let maxHR = actualMaxHR + (5 - (actualMaxHR % 5))
        let minHR = actualMinHR - (actualMinHR % 5) - 5
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
            let y = params.yForHR(hr)
            let strokeDarkness: CGFloat = labeledLine ? 0.0 : 0.6
            c.setStrokeColor(red: strokeDarkness, green: strokeDarkness, blue: strokeDarkness, alpha: 1.0)
            c.moveTo(x: params.graphRect.minX, y: y)
            c.addLineTo(x: params.graphRect.maxX, y: y)
            c.strokePath()
            if labeledLine && hr > params.minRate {
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
        if (params.barWidth > 1.0) {
            drawWideValues(params)
        } else {
            // TODO: make sure works with runs of constant values
            let c = params.context
            c.setLineWidth(1.0)
            c.setStrokeColor(params.regularBeatColor)
            var inHasHalved = false
            for pointNo in 0..<Int(params.graphRect.width) {
                let (minHR, maxHR, hasHalved) = data.summary(atPoint:pointNo, outOf:Int(params.graphRect.width))
                let maxY = params.yForHR(maxHR)
                let minY = params.yForHR(minHR)
                let x = params.graphRect.minX + CGFloat(pointNo) + 0.5
                if hasHalved != inHasHalved {
                    c.setStrokeColor(hasHalved ? params.halvedBeatColor : params.regularBeatColor)
                    inHasHalved = hasHalved
                }
                c.moveTo(x: x, y: minY)
                c.addLineTo(x: x, y: maxY)
                c.strokePath()
            }
        }
    }
    
    private func drawWideValues(_ params: ChartParams) {
        let c = params.context
        c.setLineWidth(5.0)
        c.setStrokeColor(params.regularBeatColor)
        var inHasHalved = false
        let startObs = max(0, Int(params.startObs))
        let endObs = min(data.curObservation, Int(ceil(params.startObs + params.numObs)))
        var curX = params.graphRect.minX
        if Double(startObs) < params.startObs {
            curX -= params.barWidth * CGFloat(params.startObs - Double(startObs))
        }
        for obsIndex in startObs...endObs {
            let (_, _, halved, hr) = HeartRateData.components(observation: data.observations[obsIndex])
            let y = params.yForHR(hr)
            if halved != inHasHalved {
                c.setStrokeColor(halved ? params.halvedBeatColor : params.regularBeatColor)
                inHasHalved = halved
            }
            if obsIndex == startObs {
                c.moveTo(x: max(curX, params.graphRect.minX), y: y)
            } else {
                c.addLineTo(x: curX, y: y)
            }
            curX += params.barWidth
            c.addLineTo(x: min(curX, params.graphRect.maxX), y: y)
        }
        c.strokePath()
    }
    
    private func drawTimes(_ params: ChartParams) {
        
    }
}
