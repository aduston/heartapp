//
//  SessionStorage.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/13/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation
import UIKit

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
            let success = self.saveSession(timestamp: timestamp, observations: observations)
            DispatchQueue.main.async(execute: { callback(success) })
        })
    }
    
    func numSessions() -> Int {
        let url = listingFileURL
        let fm = FileManager.default()
        if fm.fileExists(atPath: url.path!) {
            do {
                let attributes = try fm.attributesOfItem(atPath: url.path!)
                return (attributes[FileAttributeKey.size.rawValue] as! NSNumber).intValue / 4
            } catch {
                // TODO: log me.
                return 0
            }
        } else {
            return 0
        }
    }
    
    func listSessions(offset: Int, count: Int, callback: () -> [UInt32]) {
        
    }
    
    func chartImageURL(timestamp: UInt32) -> URL {
        return URL(fileURLWithPath: "data/\(timestamp).png", relativeTo: baseDirectory)
    }
    
    func sessionObservations(timestamp: UInt32, callback: () -> [UInt32]) {
        
    }
    
    func sessionData(timestamp: UInt32, callback: () -> SessionMetadata) {
        
    }
    
    private var listingFileURL: URL {
        return URL(fileURLWithPath: "listing", relativeTo: baseDirectory)
    }
    
    private func metadataFileURL(timestamp: UInt32) -> URL {
        return URL(fileURLWithPath: "data/\(timestamp).json", relativeTo: baseDirectory)
    }
    
    private func observationsFileURL(timestamp: UInt32) -> URL {
        return URL(fileURLWithPath: "data/\(timestamp).hr", relativeTo: baseDirectory)
    }
    
    private func saveSession(timestamp: UInt32, observations: [UInt32]) -> Bool {
        ensureDataDir()
        writeMetadata(timestamp: timestamp, observations: observations)
        writeObservations(timestamp: timestamp, observations: observations)
        writeImage(timestamp: timestamp, observations: observations)
        writeListingRecord(timestamp)
        return true // TODO: account for possible errors
    }
    
    private func ensureDataDir() {
        let dataDir = URL(fileURLWithPath: "data", relativeTo: baseDirectory)
        let fm = FileManager.default()
        if !fm.fileExists(atPath: dataDir.path!) {
            do {
                try fm.createDirectory(at: dataDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                // TODO: log me
            }
        }
    }
    
    private func writeMetadata(timestamp: UInt32, observations: [UInt32]) {
        // TODO: write me after you can de/serialize json
    }
    
    private func writeObservations(timestamp: UInt32, observations: [UInt32]) {
        let fileURL = observationsFileURL(timestamp: timestamp)
        let fm = FileManager.default()
        // TODO: could return false
        fm.createFile(atPath: fileURL.path!, contents: HeartRateData.observationsToData(observations: observations), attributes: nil)
    }
    
    private func writeImage(timestamp: UInt32, observations: [UInt32]) {
        let size = CGSize(width: 355, height: 200)
        UIGraphicsBeginImageContextWithOptions(size, true, CGFloat(0.0))
        let context = UIGraphicsGetCurrentContext()!
        let drawer = ChartDrawer(data: HeartRateData(observations: observations))
        drawer.draw(
            context: context,
            rect: CGRect(origin: CGPoint(x: 0, y: 0), size: size),
            startObs: 0.0,
            numObs: Double(observations.count))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        do {
            try UIImagePNGRepresentation(image)?.write(to: chartImageURL(timestamp: timestamp))
        } catch {
            // TODO: log me
        }
    }
    
    private func writeListingRecord(_ timestamp: UInt32) {
        
    }
}
