//
//  SessionStorage.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/13/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation

class SessionStorage {
    private var baseDirectory: URL
    
    convenience init() {
        let fm = FileManager.default()
        self.init(baseDirectory: fm.urlsForDirectory(.documentDirectory, inDomains: .userDomainMask)[0])
    }
    
    init(baseDirectory: URL) {
        self.baseDirectory = baseDirectory
    }
    
    func saveSession(timestamp: UInt32, observations: [UInt32], callback: (Bool) -> ()) {
        DispatchQueue.global(attributes: .qosUserInteractive).async(execute: {
            let success = self.syncSaveSession(timestamp: timestamp, observations: observations)
            DispatchQueue.main.async(execute: { callback(success) })
        })
    }
    
    func numSessions() -> Int {
        return 0
    }
    
    func listSessions(offset: Int, count: Int, callback: () -> [UInt32]) {
        
    }
    
    func sessionChartImage(timestamp: UInt32) -> URL? {
        return nil
    }
    
    func sessionObservations(timestamp: UInt32, callback: () -> [UInt32]) {
        
    }
    
    func sessionData(timestamp: UInt32, callback: () -> SessionData) {
        
    }
    
    private func syncSaveSession(timestamp: UInt32, observations: [UInt32]) -> Bool {
        writeMetadata(timestamp: timestamp, observations: observations)
        writeObservations(observations)
        writeImage(timestamp: timestamp, observations: observations)
        writeListingRecord(timestamp)
        return true
    }
    
    private func writeMetadata(timestamp: UInt32, observations: [UInt32]) {
        
    }
    
    private func writeObservations(_ observations: [UInt32]) {
        
    }
    
    private func writeImage(timestamp: UInt32, observations: [UInt32]) {
        
    }
    
    private func writeListingRecord(_ timestamp: UInt32) {
        
    }
}
