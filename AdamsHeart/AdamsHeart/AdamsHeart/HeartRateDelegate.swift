//
//  HeartRateDelegate.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/4/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation

protocol HeartRateDelegate: class {
    func heartRateServiceDidConnect(name: String)
    func heartRateServiceDidDisconnect()
    func heartRateDataArrived(data: HeartRateDataPoint)
}
