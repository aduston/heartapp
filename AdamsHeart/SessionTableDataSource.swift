//
//  SessionTableDataSource.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/15/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class SessionTableDataSource: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    static let cellId = "sessionCell"
    private var fetchedResultsController: NSFetchedResultsController<SessionMetadataMO>!
    var tableView: UITableView?
    
    init(moc: NSManagedObjectContext) {
        super.init()
        let sessionsFetch: NSFetchRequest<SessionMetadataMO> = NSFetchRequest(entityName: "SessionMetadata")
        sessionsFetch.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: sessionsFetch, managedObjectContext: moc,
            sectionNameKeyPath: nil, cacheName: "rootCache")
        fetchedResultsController.delegate = self
        do {
            // TODO: should we actually be doing this?
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections![section].numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SessionTableDataSource.cellId, for: indexPath) as! SessionTableCell
        cell.setRecord(record: sessionMetadata(at: indexPath))
        return cell
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if tableView != nil {
            tableView!.beginUpdates()
        }
    }
    
    func sessionMetadata(at indexPath: IndexPath) -> SessionMetadataMO {
        return fetchedResultsController.object(at: indexPath)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if tableView != nil {
            tableView!.endUpdates()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: AnyObject, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard tableView != nil else {
            return
        }
        switch type {
        case .insert:
            tableView!.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView!.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            break
        case .move:
            break
        }
    }
}
