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

#if os(OSX)
import Cocoa
import CoreGraphics

func callChartDrawer() {
    guard #available(OSX 10.10, *) else {return}
    let size = CGSize(width: 320, height: 300)
    let toSave = NSImage(size: size)
    toSave.lockFocus()
    let context = NSGraphicsContext.current()?.cgContext
    
    let c = ChartDrawer(data: dataSetOne())
    c.draw(context: context!, rect: CGRect(origin: CGPoint(x: 0, y: 0), size: size), startObs: 0.5, numObs: 3.5)
    
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
