//
//  RecordViewController.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/4/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import UIKit

class RecordViewController: UIViewController, HeartRateDelegate {
    private var heartRateData: HeartRateData?
    private var stopController: UIAlertController?
    @IBOutlet weak var statusLabel: UILabel?
    @IBOutlet weak var hrLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func loadView() {
        super.loadView()
        let hrChartRect = CGRect(x: 5.0, y: 100.0, width: self.view.frame.width - 10.0, height: 300.0)
        let session = Session.startOrCurrent()
        session.delegate = self
        let data = session.data
        let startObs = Double(max(0, data.curObservation - 59))
        let hrChart = HeartRateChart(
            frame: hrChartRect, data: data, type: .record,
            startObs: startObs, numObs: 60.0)
        self.view.addSubview(hrChart)
        if session.status != nil {
            statusLabel?.text = session.status
        }
    }
    
    func heartRateServiceDidConnect(name: String) {
        statusLabel!.text = name
    }

    func heartRateServiceDidDisconnect() {
        statusLabel!.text = "(Disconnected)"
    }
    
    func bluetoothTurnedOff() {
        statusLabel!.text = "Bluetooth turned off"
    }
    
    func connectionUpdate(_ status: String) {
        statusLabel!.text = status
    }
    
    func heartRateDataArrived(data: HeartRateDataPoint) {
        hrLabel?.text = String(data.hr)
    }
    
    @IBAction func doneClicked(sender: UIButton) {
        self.present(createStopController(), animated: true, completion: nil)
    }
    
    private func createStopController() -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        let destroyAction = UIAlertAction(title: "Destroy", style: .destructive) {(action) in
            self.showDestroyAlert()
        }
        alertController.addAction(destroyAction)
        let saveAction = UIAlertAction(title: "Save", style: .default) {(action) in
            let session = Session.stop()
            self.saveDataAndExit(session: session)
        }
        alertController.addAction(saveAction)
        return alertController
    }
    
    private func saveDataAndExit(session: Session?) {
        guard session != nil else {
            exitRecording()
            return
        }
        guard session!.sessionStart != nil else {
            exitRecording()
            return
        }
        // TODO: show loading screen, disable interaction
        DispatchQueue.global(attributes: .qosUserInteractive).async {
            // TODO: use return value
            _ = SessionStorage.instance.saveSession(
                timestamp: session!.sessionStart!,
                observations: session!.recordedObservations)
            DispatchQueue.main.async {
                // TODO stop showing loading screen, re-enable interaction
                self.exitRecording()
            }
        }
    }
    
    private func showDestroyAlert() {
        let alertController = UIAlertController(title: "Are you sure?", message: "You'll lose your session", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        let destroyAction = UIAlertAction(title: "Destroy", style: .destructive) {(action) in
            _ = Session.stop()
            self.exitRecording()
        }
        alertController.addAction(destroyAction)
        self.present(alertController, animated: false, completion: nil)
    }
    
    private func exitRecording() {
        dismiss(animated: true, completion: nil)
    }
}
