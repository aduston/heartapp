//
//  SessionStorage.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/13/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class SessionStorage {
    /**
     Use this instead of the constructors
     */
    static var instance = SessionStorage() // see https://developer.apple.com/swift/blog/?id=7
    
    private var baseDirectory: URL
    
    convenience init() {
        let fm = FileManager.default()
        self.init(baseDirectory: fm.urlsForDirectory(.documentDirectory, inDomains: .userDomainMask)[0])
    }
    
    init(baseDirectory: URL) {
        self.baseDirectory = baseDirectory
    }
    
    func saveSession(timestamp: UInt32, observations: [Observation]) -> Bool {
        ensureDataDir()
        writeObservations(timestamp: timestamp, observations: observations)
        writeImage(timestamp: timestamp, observations: observations)
        writeSessionMetadataRecord(timestamp)
        return true // TODO: account for other possible errors
    }
    
    func listSessions(timestampsLessThan: UInt32, limit: Int) -> [SessionMetadataMO]? {
        let moc = coreDataController.managedObjectContext
        let sessionsFetch: NSFetchRequest<SessionMetadataMO> = NSFetchRequest(entityName: "SessionMetadata")
        sessionsFetch.predicate = Predicate(format: "timestamp < %@", NSNumber(value: timestampsLessThan))
        sessionsFetch.sortDescriptors = [SortDescriptor(key: "timestamp", ascending: false)]
        sessionsFetch.fetchLimit = limit
        do {
            return try moc.fetch(sessionsFetch)
        } catch {
            return nil
        }
    }
    
    func chartImageURL(timestamp: UInt32) -> URL {
        return URL(fileURLWithPath: "data/\(timestamp).png", relativeTo: baseDirectory)
    }
    
    func sessionObservations(timestamp: UInt32) -> [Observation]? {
        var fh: FileHandle?
        do {
            fh = try FileHandle(forReadingFrom: observationsFileURL(timestamp: timestamp))
        } catch {
            // TODO: what to do?
            return nil
        }
        let data = fh?.readDataToEndOfFile()
        fh?.closeFile()
        return HeartRateData.dataToObservations(data: data!)
    }
    
    private lazy var coreDataController: CoreDataController = {
        return CoreDataController(async: false)
    }()
    
    private func metadataFileURL(timestamp: UInt32) -> URL {
        return URL(fileURLWithPath: "data/\(timestamp).json", relativeTo: baseDirectory)
    }
    
    private func observationsFileURL(timestamp: UInt32) -> URL {
        return URL(fileURLWithPath: "data/\(timestamp).hr", relativeTo: baseDirectory)
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
    
    private func writeObservations(timestamp: UInt32, observations: [Observation]) {
        let fileURL = observationsFileURL(timestamp: timestamp)
        let fm = FileManager.default()
        // TODO: could return false
        fm.createFile(atPath: fileURL.path!, contents: HeartRateData.observationsToData(observations: observations), attributes: nil)
    }
    
    private func writeImage(timestamp: UInt32, observations: [Observation]) {
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
            // TODO: log me, return false or throw error
        }
    }
    
    private func writeSessionMetadataRecord(_ timestamp: UInt32) {
        let moc = coreDataController.managedObjectContext
        let sessionMetadata = NSEntityDescription.insertNewObject(forEntityName: "SessionMetadata", into: moc) as! SessionMetadataMO
        sessionMetadata.onServerValue = false
        sessionMetadata.timestampValue = timestamp
        coreDataController.save()
    }
}