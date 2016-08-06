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
    static let minRate: UInt8 = 35
    static let maxRate: UInt8 = 175
    static let spaceLeft: CGFloat = 30
    static let spaceBottom: CGFloat = 20
    static let labelFont = NSUIFont(name: "Helvetica", size: 14)!
    static let regularBeatStroke = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components:[0.0, 0.0, 0.7, 1.0])!
    static let halvedBeatStroke = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components:[0.7, 0.0, 0.0, 1.0])!
    static let regularBeatFill = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components:[0.0, 0.0, 1.0, 0.5])!
    static let halvedBeatFill = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components:[1.0, 0.0, 0.0, 0.5])!
    
    let context: CGContext
    let rect: CGRect
    let startObs: Double
    let numObs: Double
    let graphRect: CGRect
    let beatHeight: CGFloat
    let barWidth: CGFloat
    
    static func create(context: CGContext, rect: CGRect, startObs: Double, numObs: Double) -> ChartParams {
        let graphRect = ChartParams.graphRect(viewRect: rect)
        let beatHeight = maxRate == minRate ? 0 : graphRect.size.height / CGFloat(maxRate - minRate)
        let barWidth = graphRect.width / CGFloat(numObs)
        return ChartParams(context: context, rect: rect, startObs: startObs, numObs: numObs,
                           graphRect: graphRect, beatHeight: beatHeight, barWidth: barWidth)
    }
    
    static func graphRect(viewRect: CGRect) -> CGRect {
        return CGRect(
            x: viewRect.minX + ChartParams.spaceLeft,
            y: viewRect.minY + ChartParams.spaceBottom,
            width: viewRect.width - ChartParams.spaceLeft,
            height: viewRect.height - ChartParams.spaceBottom * 2)
    }
    
    func yForHR(_ hr: UInt8) -> CGFloat {
        let clampedHR = max(ChartParams.minRate, min(ChartParams.maxRate, hr))
        return graphRect.maxY - (CGFloat(clampedHR - ChartParams.minRate) * beatHeight)
    }
}

public class ChartDrawer {
    static let maxNumBars = 180;
    private var data : HeartRateData
    
    init(data: HeartRateData) {
        self.data = data
    }
    
    public func draw(context: CGContext, rect: CGRect, startObs: Double, numObs: Double) {
        let params = ChartParams.create(
            context: context, rect: rect, startObs: startObs, numObs: numObs)
        drawBackground(params)
        drawHorizontalLines(params)
        if data.curObservation > -1 {
            drawValues(params)
            drawTimes(params)
        }
    }
    
    private func drawBackground(_ params: ChartParams) {
        params.context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        params.context.fill(params.rect)
    }
    
    private func drawHorizontalLines(_ params: ChartParams) {
        let c = params.context
        c.setLineWidth(1.0)
        for hr in ChartParams.minRate...ChartParams.maxRate {
            if hr % 5 != 0 {
                continue
            }
            let labeledLine = hr % 10 == 0
            let y = params.yForHR(hr)
            let strokeDarkness: CGFloat = labeledLine ? 0.0 : 0.7
            c.setStrokeColor(red: strokeDarkness, green: strokeDarkness, blue: strokeDarkness, alpha: 1.0)
            c.moveTo(x: params.graphRect.minX, y: y)
            c.addLineTo(x: params.graphRect.maxX, y: y)
            c.strokePath()
            if labeledLine && hr > ChartParams.minRate {
                addHRLabel(params: params, hr: hr, y: y)
            }
        }
    }
    
    private func addHRLabel(params: ChartParams, hr: UInt8, y: CGFloat) {
        let label = String(hr) as NSString
        #if os(iOS)
        let labelSize = label.size(attributes: [NSFontAttributeName: ChartParams.labelFont])
        #elseif os(OSX)
        let labelSize = label.size(withAttributes: [NSFontAttributeName: params.labelFont])
        #endif
        let point = CGPoint(x: params.graphRect.minX - 2 - labelSize.width,
                            y: y - (labelSize.height / 2.0))
        label.draw(at: point, withAttributes: [NSFontAttributeName: ChartParams.labelFont])
    }
    
    private func drawValues(_ params: ChartParams) {
        let maxNumBars = ChartDrawer.maxNumBars
        if params.numObs <= Double(maxNumBars) {
            drawWideValues(params)
        } else {
            let obsPerBar = params.numObs / Double(maxNumBars)
            let pixelsPerObs = Double(params.graphRect.width) / params.numObs
            let pixelsPerBar = Double(params.graphRect.width) / Double(maxNumBars)
            // obsStartX is the X position of observation 0.
            let obsStartX = Double(params.graphRect.minX) - params.startObs * pixelsPerObs
            // the zeroth bar index starts at observation 0 at obsStartX
            var barIndex = Int(params.startObs / obsPerBar)
            var x = obsStartX + Double(barIndex) * pixelsPerBar
            while x < Double(params.graphRect.maxX) {
                if x + pixelsPerBar < Double(params.graphRect.minX) {
                    // too far to the left
                    continue
                }
                let (minHR, maxHR, hasHalved) = data.summary(
                    startObs: Double(barIndex) * obsPerBar,
                    endObs: Double(barIndex + 1) * obsPerBar)
                let maxY = params.yForHR(maxHR)
                let minY = params.yForHR(minHR)
                let valueStrokeColor = hasHalved ? ChartParams.halvedBeatStroke : ChartParams.regularBeatStroke
                let valueFillColor = hasHalved ? ChartParams.halvedBeatFill : ChartParams.regularBeatFill
                drawGraphValueLine(
                    params, x: CGFloat(x), y0: minY, y1: maxY,
                    width: CGFloat(pixelsPerBar), color: valueStrokeColor)
                drawGraphValueLine(
                    params, x: CGFloat(x), y0: params.graphRect.maxY, y1: maxY,
                    width: CGFloat(pixelsPerBar), color: valueFillColor)
                barIndex += 1
                x = obsStartX + Double(barIndex) * pixelsPerBar
            }
        }
    }
    
    private func drawGraphValueLine(_ params: ChartParams, x: CGFloat, y0: CGFloat, y1: CGFloat, width: CGFloat, color: CGColor) {
        let c = params.context
        let lineMinX = max(x, params.graphRect.minX)
        let actualWidth = min(width, x + width - params.graphRect.minX, params.graphRect.maxX - x)
        let lineX = lineMinX + actualWidth / 2.0
        c.beginPath()
        c.setStrokeColor(color)
        c.setLineWidth(actualWidth)
        c.moveTo(x: lineX, y: y0)
        c.addLineTo(x: lineX, y: y1)
        c.strokePath()
    }
    
    private func drawWideValues(_ params: ChartParams) {
        let c = params.context
        c.setFillColor(ChartParams.regularBeatFill)
        var inHasHalved = false
        let startObs = max(0, Int(params.startObs))
        let endObs = min(data.curObservation, Int(ceil(params.startObs + params.numObs)))
        var curX = params.graphRect.minX
        if Double(startObs) < params.startObs {
            curX -= params.barWidth * CGFloat(params.startObs - Double(startObs))
        }
        for obsIndex in startObs...endObs {
            let (_, halved, hr) = HeartRateData.components(observation: data.observations[obsIndex])
            if halved != inHasHalved {
                c.setFillColor(halved ? ChartParams.halvedBeatFill : ChartParams.regularBeatFill)
                inHasHalved = halved
            }
            let y = params.yForHR(hr)
            let x = max(params.graphRect.minX, curX)
            let nextX = min(curX + params.barWidth, params.graphRect.maxX)
            c.fill(CGRect(x: x,
                          y: y,
                          width: nextX - x,
                          height: params.graphRect.maxY - y))
            curX = nextX
        }
    }
    
    private func drawTimes(_ params: ChartParams) {
        // TODO: write me
    }
}
