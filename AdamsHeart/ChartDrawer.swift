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
    static let xLabelWidth: CGFloat = 60
    static let minRate: UInt8 = 35
    static let maxRate: UInt8 = 175
    static let spaceLeft: CGFloat = 30
    static let spaceBottom: CGFloat = 25
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
            let labeledMultiple = UInt32(findLabeledMultiple(params))
            let obsPerBar = params.numObs / Double(maxNumBars)
            let pixelsPerObs = Double(params.graphRect.width) / params.numObs
            let pixelsPerBar = Double(params.graphRect.width) / Double(maxNumBars)
            // obsStartX is the X position of observation 0.
            let obsStartX = Double(params.graphRect.minX) - params.startObs * pixelsPerObs
            // the zeroth bar index starts at observation 0 at obsStartX
            var barIndex = Int(params.startObs / obsPerBar)
            var x = obsStartX + Double(barIndex) * pixelsPerBar
            var lastLabelX: CGFloat = 0
            while x < Double(params.graphRect.maxX) {
                if x + pixelsPerBar < Double(params.graphRect.minX) {
                    // too far to the left
                    continue
                }
                let (minSeconds, maxSeconds, minHR, maxHR, hasHalved) = data.summary(
                    startObs: Double(barIndex) * obsPerBar,
                    endObs: Double(barIndex + 1) * obsPerBar)
                let maxY = params.yForHR(maxHR)
                let minY = params.yForHR(minHR)
                let valueStrokeColor = hasHalved ? ChartParams.halvedBeatStroke : ChartParams.regularBeatStroke
                let valueFillColor = hasHalved ? ChartParams.halvedBeatFill : ChartParams.regularBeatFill
                let lineX = drawGraphValueLine(
                    params, x: CGFloat(x), y0: minY, y1: maxY,
                    width: CGFloat(pixelsPerBar), color: valueStrokeColor)
                _ = drawGraphValueLine(
                    params, x: CGFloat(x), y0: params.graphRect.maxY, y1: maxY,
                    width: CGFloat(pixelsPerBar), color: valueFillColor)
                if lastLabelX == 0 || lastLabelX < CGFloat(x) - ChartParams.xLabelWidth / 2.0 {
                    let newLabelX = maybeDrawXLabel(params, minSeconds: minSeconds, maxSeconds: maxSeconds, labeledMultiple: labeledMultiple, lineX: lineX)
                    if newLabelX != 0.0 {
                        lastLabelX = newLabelX
                    }
                }
                barIndex += 1
                x = obsStartX + Double(barIndex) * pixelsPerBar
            }
        }
    }
    
    private func maybeDrawXLabel(_ params: ChartParams, minSeconds: UInt32, maxSeconds: UInt32, labeledMultiple: UInt32, lineX: CGFloat) -> CGFloat {
        for seconds in minSeconds...maxSeconds {
            if seconds % labeledMultiple == 0 {
                return drawXLabel(params, midX: lineX, seconds: seconds)
            }
        }
        return 0.0
    }
    
    private func drawGraphValueLine(_ params: ChartParams, x: CGFloat, y0: CGFloat, y1: CGFloat, width: CGFloat, color: CGColor) -> CGFloat {
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
        return lineX
    }
    
    private func drawWideValues(_ params: ChartParams) {
        let labeledMultiple = UInt32(findLabeledMultiple(params))
        let c = params.context
        c.setFillColor(ChartParams.regularBeatFill)
        var inHasHalved = false
        let startObs = max(0, Int(params.startObs))
        let endObs = min(data.curObservation, Int(ceil(params.startObs + params.numObs)))
        var curX = params.graphRect.minX
        if Double(startObs) < params.startObs {
            curX -= params.barWidth * CGFloat(params.startObs - Double(startObs))
        }
        var lastLabelX: CGFloat = 0
        for obsIndex in startObs...endObs {
            let (seconds, halved, hr) = HeartRateData.components(observation: data.observations[obsIndex])
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
            let midX = (x + nextX) / 2.0
            if seconds % labeledMultiple == 0 && lastLabelX < midX - ChartParams.xLabelWidth / 2.0 {
                lastLabelX = drawXLabel(params, midX: midX, seconds: seconds)
                // without this fill color gets reset
                c.setFillColor(inHasHalved ? ChartParams.halvedBeatFill : ChartParams.regularBeatFill)
            }
            curX = nextX
        }
    }
    
    private func findLabeledMultiple(_ params: ChartParams) -> Int {
        let maxNumLabels = Double(params.graphRect.width / ChartParams.xLabelWidth)
        let obsPerLabel = Int(params.numObs / maxNumLabels)
        let intervals: [Int] = [5, 15, 30, 60, 300, 600, 900, 1800, 3600, 7200];
        for i in 0..<intervals.count {
            if obsPerLabel < intervals[i] {
                return intervals[i]
            }
        }
        return 18000
    }
    
    private func drawXLabel(_ params: ChartParams, midX: CGFloat, seconds: UInt32) -> CGFloat {
        if midX >= params.graphRect.minX && midX < params.graphRect.maxX {
            let c = params.context
            c.beginPath()
            c.setStrokeColor(CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components:[0.0, 0.0, 0.0, 1.0])!)
            c.setLineWidth(1.0)
            c.moveTo(x: midX, y: params.graphRect.maxY)
            c.addLineTo(x: midX, y: params.graphRect.maxY + 5)
            c.strokePath()
        } else {
            return 0.0
        }
        let label = timeLabelText(seconds) as NSString
        #if os(iOS)
            let labelSize = label.size(attributes: [NSFontAttributeName: ChartParams.labelFont])
        #elseif os(OSX)
            let labelSize = label.size(withAttributes: [NSFontAttributeName: params.labelFont])
        #endif
        
        let point = CGPoint(x: midX - labelSize.width / 2.0,
                            y: params.graphRect.maxY + 7)
        label.draw(at: point, withAttributes: [NSFontAttributeName: ChartParams.labelFont])
        return midX + labelSize.width / 2.0
    }
    
    private func timeLabelText(_ seconds: UInt32) -> String {
        if seconds < 60 {
            return String(format: "0:%02d", seconds)
        } else if seconds < 3600 {
            return String(format: "%d:%02d", seconds / 60, seconds % 60)
        } else {
            return String(format: "%d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
        }
    }
}
