//
//  main.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/9/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

#if os(OSX)
import Cocoa
import CoreGraphics

func callChartDrawer() {
    guard #available(OSX 10.10, *) else {return}
    let size = CGSize(width: 300, height: 300)
    let toSave = NSImage(size: size)
    toSave.lockFocus()
    let context = NSGraphicsContext.current()?.cgContext
    
    // draw
    let c = ChartDrawer(data: HeartRateData())
    c.draw(context: context!, rect: CGRect(origin: CGPoint(x: 0, y: 0), size: size), startObs: 0.5, numObs: 40.0)
    
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

print("doing something")
callChartDrawer()
#endif
