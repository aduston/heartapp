//
//  ViewController.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/4/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import UIKit
import CoreData

class MainViewController: UIViewController, UITableViewDelegate {
    @IBOutlet weak var sessionTable: UITableView?
    var sessionTableDataSource: SessionTableDataSource?

    override func viewDidLoad() {
        super.viewDidLoad()
        if sessionTableDataSource == nil {
            // loading screen should be showing here.
            DispatchQueue.global(attributes: .qosUserInteractive).async {
                // note the following call is potentially long-running.
                let moc = SessionStorage.instance.coreDataController.managedObjectContext
                DispatchQueue.main.async {
                    // TODO: should the following instantiation be in main thread?
                    self.sessionTableDataSource = SessionTableDataSource(moc: moc)
                    self.setUpTable()
                    // TODO: get rid of loading screen.
                }
            }
        }
    }
    
    private func setUpTable() {
        sessionTable!.register(SessionTableCell.self, forCellReuseIdentifier: SessionTableDataSource.cellId)
        sessionTable!.delegate = self
        sessionTable!.dataSource = self.sessionTableDataSource!
        sessionTable!.separatorStyle = .none
        sessionTable!.reloadData()
        self.sessionTableDataSource?.tableView = sessionTable
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return SessionTableCell.cellHeight
    }
}

