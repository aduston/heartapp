//
//  CoreDataController.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/14/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import CoreData
import Foundation

class CoreDataController {
    var managedObjectContext: NSManagedObjectContext

    init(async: Bool) {
        // This resource is the same name as your xcdatamodeld contained in your project.
        guard let modelURL = Bundle.main().urlForResource("DataModel", withExtension: "momd") else {
            fatalError("Error loading model from bundle")
        }
        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = psc
        if async {
            DispatchQueue.global(attributes: .qosBackground).async {
                self.addPersistentStore(psc: psc)
            }
        } else {
            addPersistentStore(psc: psc)
        }
    }
    
    private func addPersistentStore(psc : NSPersistentStoreCoordinator) {
        let docURL = FileManager.default().urlsForDirectory(.documentDirectory, inDomains: .userDomainMask).last!
        /* The directory the application uses to store the Core Data store file.
         This code uses a file named "DataModel.sqlite" in the application's documents directory.
         */
        let storeURL = URL(fileURLWithPath: "DataModel.sqlite", relativeTo: docURL)
        do {
            try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
        } catch {
            fatalError("Error migrating store: \(error)")
        }
    }
    
    func save() {
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
    }
}