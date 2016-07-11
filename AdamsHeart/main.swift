//
//  main.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/9/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

func dataSetOne() -> HeartRateData {
    let hrData = HeartRateData()
    hrData.addObservation(heartRate: 70, elapsedSeconds: 0)
    hrData.addObservation(heartRate: 73, elapsedSeconds: 1)
    hrData.addObservation(heartRate: 78, elapsedSeconds: 2)
    hrData.addObservation(heartRate: 74, elapsedSeconds: 3)
    return hrData
}

func dataSetTwo() -> HeartRateData {
    let hrData = HeartRateData()
    for i in 0...500 {
        let val = 80 + (i % 90)
        hrData.addObservation(heartRate: UInt8(val), elapsedSeconds: i)
    }
    return hrData
}

#if os(OSX)
import Cocoa
import CoreGraphics

func callChartDrawer() {
    guard #available(OSX 10.10, *) else {return}
    let size = CGSize(width: 320, height: 300)
    let toSave = NSImage(size: size)
    toSave.lockFocus()
    let context = NSGraphicsContext.current()?.cgContext
    
    let c = ChartDrawer(data: dataSetTwo())
    c.draw(context: context!, rect: CGRect(origin: CGPoint(x: 0, y: 0), size: size), startObs: 40.0, numObs: 460.0)
    
    let rep = NSBitmapImageRep(focusedViewRect: NSRect(origin: CGPoint(x: 0, y: 0), size: size))
    toSave.unlockFocus()
    let data = rep!.representation(using: .PNG, properties: [:])
    do {
        print("saving to output.png")
        try data?.write(to: URL(fileURLWithPath: "/Users/aduston/output.png"))
    } catch {
        print(error)
    }
}

callChartDrawer()
#endif
