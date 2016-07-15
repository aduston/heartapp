//
//  ViewController.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/4/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
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
                    self.sessionTable?.dataSource = self.sessionTableDataSource!
                    self.sessionTable?.reloadData()
                    // TODO: get rid of loading screen.
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

