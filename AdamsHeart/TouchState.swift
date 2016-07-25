//
//  TouchState.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/24/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation
import UIKit

struct TouchState {
    /**
     Contains starting position of touches
     */
    private let touches: [UITouch:CGPoint]
    /**
     startObs of HeartRateChart when these touches are started
     */
    private let touchStartStartObs: Double
    /**
     numObs of HeartRateChart when these touches are started
     */
    private let touchStartNumObs: Double
    private let view: UIView
    private let chartRect: CGRect
    
    static func newState(touches: Set<UITouch>, startObs: Double, numObs: Double, view: UIView, chartRect: CGRect) -> TouchState? {
        if touches.count == 1 || touches.count == 2 {
            return TouchState(touches: newTouchesCopy(touches, inView: view, withRect: chartRect),
                              touchStartStartObs: startObs,
                              touchStartNumObs: numObs,
                              view: view,
                              chartRect: chartRect)
        } else {
            return nil
        }
    }
    
    func newState(afterAdding touches: Set<UITouch>) -> TouchState? {
        var newTouches = TouchState.newTouchesCopy(Set<UITouch>(self.touches.keys), inView: view, withRect: chartRect)
        for touch in touches {
            newTouches[touch] = TouchState.touchPosition(touch, inView: view, withRect: chartRect)
        }
        return newState(withStartTouches: newTouches)
    }
    
    func newState(afterRemoving touches: Set<UITouch>) -> TouchState? {
        var newTouches = TouchState.newTouchesCopy(Set<UITouch>(self.touches.keys), inView: view, withRect: chartRect)
        for touch in touches {
            newTouches.removeValue(forKey: touch)
        }
        return newState(withStartTouches: newTouches)
    }
    
    func curStartAndNumObs() -> (Double, Double) {
        if touches.count == 2 {
            let (start, end) = startAndEndPoints()
            let numObs = touchStartNumObs * Double((start[0].x - start[1].x) / (end[0].x - end[1].x))
            let startMidPos = Double((start[0].x + start[1].x) / 2.0)
            let endMidPos = Double((end[0].x + end[1].x) / 2.0)
            let startObs = touchStartStartObs + (startMidPos * touchStartNumObs - endMidPos * numObs) / Double(chartRect.width)
            return (startObs, numObs)
        } else {
            let touch = touches.first!
            let start = touch.value
            let end = TouchState.touchPosition(touch.key, inView: view, withRect: chartRect)
            let ratio = Double((end.x - start.x) / chartRect.width)
            let addedNumObs = touchStartNumObs * ratio
            return (touchStartStartObs - addedNumObs, touchStartNumObs)
        }
    }
    
    private func startAndEndPoints() -> ([CGPoint], [CGPoint]) {
        var start = [CGPoint](repeating: CGPoint(), count: 2)
        var end = [CGPoint](repeating: CGPoint(), count: 2)
        var i = 0
        for (touch, startPos) in touches {
            start[i] = startPos
            end[i] = TouchState.touchPosition(touch, inView: view, withRect: chartRect)
            i += 1
        }
        return (start, end)
    }
    
    private static func touchPosition(_ touch: UITouch, inView view: UIView, withRect rect:CGRect) -> CGPoint {
        let touchPoint = touch.location(in: view)
        let origin = rect.origin
        return CGPoint(x: touchPoint.x - origin.x, y: touchPoint.y - origin.y)
    }

    private static func newTouchesCopy(_ touches: Set<UITouch>, inView view: UIView, withRect rect:CGRect) -> [UITouch:CGPoint] {
        var newTouches = [UITouch:CGPoint]()
        for curTouch in touches {
            newTouches[curTouch] = touchPosition(curTouch, inView: view, withRect: rect)
        }
        return newTouches;
    }
    
    private func newState(withStartTouches newTouches: [UITouch:CGPoint]) -> TouchState? {
        let (startObs, numObs) = curStartAndNumObs()
        if newTouches.count == 1 || newTouches.count == 2 {
            return TouchState(
                touches: newTouches,
                touchStartStartObs: startObs,
                touchStartNumObs: numObs,
                view: view,
                chartRect: chartRect)
        } else {
            return nil
        }
    }
}
