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
        var energyExpended: Bool
        var rrInterval: Bool
        init(flag : UInt8) {
            hrFormat = flag & 0x1
            sensorContact = (flag >> 1) & 0x3
            energyExpended = ((flag >> 3) & 0x1) != 0
            rrInterval = ((flag >> 4) & 0x1) != 0
        }
        var hrSize: Int {
            return Int(hrFormat) + 1;
        }
    }

    let heartRateServiceUUID = CBUUID(string: "180D");
    let heartRateMeasurementUUID = CBUUID(string: "2A37");
    
    private var delegate: HeartRateDelegate?;
    private var running: Bool
    private var manager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?

    init(delegate: HeartRateDelegate) {
        running = false
        self.delegate = delegate;
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func start() {
        running = true
        if manager!.state != .poweredOn {
            // TODO: log
            delegate!.bluetoothTurnedOff()
        } else {
            scanForPeripherals()
        }
    }
    
    func stop() {
        running = false
        // TODO!
        if connectedPeripheral != nil {
            
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard running else {
            return
        }
        // TODO: log this
        if manager!.state == .poweredOn {
            scanForPeripherals()
        }
    }
    
    private func scanForPeripherals() {
        delegate!.connectionUpdate("Scanning for peripherals")
        manager!.scanForPeripherals(withServices: [heartRateServiceUUID], options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : AnyObject], rssi RSSI: NSNumber) {
        guard running else {
            return
        }
        // TODO: log peripheral name
        // TODO: connecting to first found peripheral here may not be the best policy.
        // one way to handle is let the user make feedback about "wrong peripheral", then either ban or soft-ban that peripheral.
        delegate!.connectionUpdate("Discovered \(peripheral.name!)")
        connectedPeripheral = peripheral
        manager!.connect(peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: NSNumber(value: true)])
        manager!.stopScan()
    }
    
    /**
      Invoked when a connection is successfully created with a peripheral
     */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard running else {
            return
        }
        delegate!.connectionUpdate("Connected \(peripheral.name!)")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    /**
     Invoked whenever an existing connection with the peripheral is torn down.
    */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // TODO: start scanning again, periodically
        if delegate != nil {
            delegate!.heartRateServiceDidDisconnect()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard running && error == nil else {
            // TODO log, cleanup?
            return
        }
        delegate!.connectionUpdate("Discovered services for \(peripheral.name!)")
        let services = peripheral.services;
        for service in services! {
            if service.uuid.isEqual(heartRateServiceUUID) {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            // TODO: log, cleanup?
            return
        }
        guard service.uuid.isEqual(heartRateServiceUUID) else {
            return
        }
        for characteristic in service.characteristics! {
            if characteristic.uuid.isEqual(heartRateMeasurementUUID) {
                peripheral.setNotifyValue(true, for: characteristic)
                delegate!.heartRateServiceDidConnect(name: peripheral.name == nil ? "(unknown)" : peripheral.name!)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            // TODO: log, cleanup?
            return
        }
        guard characteristic.uuid.isEqual(heartRateMeasurementUUID) else {
            return
        }
        let data = characteristic.value!;
        let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        data.copyBytes(to: bytes, count: data.count)
        let flags = HeartRateFlags(flag: bytes[0])
        var hr: UInt16
        let sensorContact = flags.sensorContact
        var energy: UInt16?
        var rrInterval: UInt16?
        if flags.hrSize == 1 {
            hr = UInt16(bytes[1])
        } else {
            hr = CFSwapInt16LittleToHost(UnsafeRawPointer(bytes + 1).load(as: UInt16.self))
        }
        var curOffset = 1 + flags.hrSize
        if flags.energyExpended {
            energy = CFSwapInt16LittleToHost(UnsafeRawPointer(bytes + curOffset).load(as: UInt16.self))
            curOffset += 2
        }
        if flags.rrInterval {
            rrInterval = CFSwapInt16LittleToHost(UnsafeRawPointer(bytes + curOffset).load(as: UInt16.self))
            rrInterval = UInt16(Double(rrInterval!) / 1024.0 * 1000.0)
        }
        // TODO: is this the right sequence of calls to dealloc?
        bytes.deinitialize()
        bytes.deallocate(capacity: data.count)
        let dataPoint = HeartRateDataPoint(
            hr: hr, sensorContact: sensorContact,
            energy: energy, rrInterval: rrInterval)
        delegate!.heartRateDataArrived(data: dataPoint)
    }
}
