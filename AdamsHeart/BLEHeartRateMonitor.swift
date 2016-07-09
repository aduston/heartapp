//
//  BLEHeartRateMonitor.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/4/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation
import CoreBluetooth

class BLEHeartRateMonitor: NSObject, HeartRateMonitor, CBCentralManagerDelegate, CBPeripheralDelegate {
    struct HeartRateFlags {
        var hrFormat: UInt8
        var sensorContact: UInt8
        var energyExpended: UInt8
        var rrInterval: UInt8
        init(flag : UInt8) {
            hrFormat = flag & 0x1;
            sensorContact = (flag >> 1) & 0x3;
            energyExpended = (flag >> 3) & 0x1;
            rrInterval = (flag >> 4) & 0x1;
        }
        func getHRSize() -> Int {
            return Int(hrFormat) + 1;
        }
    }
    let heartRateServiceUUID = CBUUID(string: "180D");
    let heartRateMeasurementUUID = CBUUID(string: "2A37");
    
    private var delegate: HeartRateDelegate;

    init(delegate: HeartRateDelegate) {
        self.delegate = delegate;
    }
    
    func start() {
        
    }
    
    func stop() {
        
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            return
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        guard error == nil else {
            // TODO log, cleanup?
            return
        }
        let services = peripheral.services;
        for service in services! {
            if service.uuid.isEqual(heartRateServiceUUID) {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: NSError?) {
        guard error == nil else {
            // TODO: log, cleanup?
            return
        }
        guard service.uuid.isEqual(heartRateServiceUUID) else {
            // TODO: log, cleanup?
            return
        }
        for characteristic in service.characteristics! {
            if characteristic.uuid.isEqual(heartRateMeasurementUUID) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: NSError?) {
        guard error == nil else {
            // TODO: log, cleanup?
            return
        }
        guard characteristic.uuid.isEqual(heartRateMeasurementUUID) else {
            return
        }
        let data = characteristic.value!;
        var buffer = [UInt8](repeating: 0x00, count: data.count)
        
    }
}
