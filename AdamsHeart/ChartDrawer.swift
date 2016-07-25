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
    static let spaceLeft: CGFloat = 30
    static let spaceBottom: CGFloat = 20
    static let labelFont = NSUIFont(name: "Helvetica", size: 14)!
    static let regularBeatStroke = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components:[0.0, 0.0, 1.0, 1.0])!
    static let halvedBeatStroke = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components:[1.0, 0.0, 0.0, 1.0])!
    static let regularBeatFill = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components:[0.0, 0.0, 1.0, 0.5])!
    static let halvedBeatFill = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components:[1.0, 0.0, 0.0, 0.8])!
    
    let context: CGContext
    let rect: CGRect
    let startObs: Double
    let numObs: Double
    let minRate: UInt8
    let maxRate: UInt8
    let graphRect: CGRect
    let beatHeight: CGFloat
    let spread: UInt8
    let barWidth: CGFloat
    
    static func create(context: CGContext, rect: CGRect, startObs: Double, numObs: Double, minRate: UInt8, maxRate: UInt8) -> ChartParams {
        let graphRect = ChartParams.graphRect(viewRect: rect)
        let beatHeight = maxRate == minRate ? 0 : graphRect.size.height / CGFloat(maxRate - minRate)
        let spread = maxRate - minRate
        let barWidth = graphRect.width / CGFloat(numObs)
        return ChartParams(context: context, rect: rect, startObs: startObs, numObs: numObs, minRate: minRate, maxRate: maxRate, graphRect: graphRect, beatHeight: beatHeight, spread: spread, barWidth: barWidth)
    }
    
    static func graphRect(viewRect: CGRect) -> CGRect {
        return CGRect(
            x: viewRect.minX + ChartParams.spaceLeft,
            y: viewRect.minY + ChartParams.spaceBottom,
            width: viewRect.width - ChartParams.spaceLeft,
            height: viewRect.height - ChartParams.spaceBottom * 2)
    }
    
    func yForHR(_ hr: UInt8) -> CGFloat {
        return graphRect.maxY - (CGFloat(hr - minRate) * beatHeight)
    }
}

public class ChartDrawer {
    private var data : HeartRateData
    
    init(data: HeartRateData) {
        self.data = data
    }
    
    public func draw(context: CGContext, rect: CGRect, startObs: Double, numObs: Double) {
        let (actualMinHR, actualMaxHR) = data.minAndMax(startObs: Int(startObs), numObs: Int(ceil(numObs)) + 1)
        guard actualMaxHR != 0 else {
            context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            context.fill(rect)
            return
        }
        let maxHR = actualMaxHR + (5 - (actualMaxHR % 5))
        let minHR = actualMinHR - (actualMinHR % 5) - 5
        let params = ChartParams.create(
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
        let labelSize = label.size(attributes: [NSFontAttributeName: ChartParams.labelFont])
        #elseif os(OSX)
        let labelSize = label.size(withAttributes: [NSFontAttributeName: params.labelFont])
        #endif
        let point = CGPoint(x: params.graphRect.minX - 2 - labelSize.width,
                            y: y - (labelSize.height / 2.0))
        label.draw(at: point, withAttributes: [NSFontAttributeName: ChartParams.labelFont])
    }
    
    private func drawValues(_ params: ChartParams) {
        if (params.barWidth > 1.0) {
            drawWideValues(params)
        } else {
            // TODO: make sure works with runs of constant values
            let c = params.context
            c.setLineWidth(1.0)
            c.setStrokeColor(ChartParams.regularBeatStroke)
            c.beginPath()
            var inHasHalved = false
            let obsPerPoint = params.numObs / Double(params.graphRect.width)
            for pointNo in 0..<Int(params.graphRect.width) {
                let (minHR, maxHR, hasHalved) = data.summary(
                    startObs: params.startObs + Double(pointNo) * obsPerPoint,
                    endObs: params.startObs + Double(pointNo + 1) * obsPerPoint)
                let maxY = params.yForHR(maxHR)
                let minY = params.yForHR(minHR)
                let x = params.graphRect.minX + CGFloat(pointNo) + 0.5
                if hasHalved != inHasHalved {
                    if pointNo > 0 {
                        c.strokePath()
                    }
                    c.beginPath()
                    c.setStrokeColor(hasHalved ? ChartParams.halvedBeatStroke : ChartParams.regularBeatStroke)
                    inHasHalved = hasHalved
                }
                c.moveTo(x: x, y: minY)
                c.addLineTo(x: x, y: maxY)
            }
            c.strokePath()
        }
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
