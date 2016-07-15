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
    private let cellId = "sessionCell"
    private var fetchedResultsController: NSFetchedResultsController<SessionMetadataMO>!
    
    init(moc: NSManagedObjectContext) {
        super.init()
        let sessionsFetch: NSFetchRequest<SessionMetadataMO> = NSFetchRequest(entityName: "SessionMetadata")
        sessionsFetch.sortDescriptors = [SortDescriptor(key: "timestamp", ascending: false)]
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
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        configureCell(cell: cell, indexPath: indexPath)
        return cell
    }
    
    private func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        let sessionMetadata = fetchedResultsController.object(at: indexPath)
        // TODO: set up cell using that sessionMetadata
    }
}
