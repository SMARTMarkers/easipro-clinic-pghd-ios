//
//  RequestViewController.swift
//  EASIPRO-Clinic
//
//  Created by Raheel Sayeed on 10/25/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import UIKit
import SMARTMarkers
import SMART

class RequestOrderViewController: UITableViewController {
    
    // Get fhir manager from the appDelegate
    lazy var fhir: FHIRManager! = {
        return (UIApplication.shared.delegate as! AppDelegate).fhir
    }()
    
    let dateFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var task: TaskController!
    var server: Server!
    var patient: Patient!
    var practitioner: Practitioner?

    var startDate = Date() {
        didSet {
            let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1))
            cell?.detailTextLabel?.text = dateFormat.string(from: startDate)
        }
    }
    var endDate = Date() {
        didSet {
            let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 1))
            cell?.detailTextLabel?.text = dateFormat.string(from: endDate)
        }
    }
    
    
    let activityIndicator = UIActivityIndicatorView.init(activityIndicatorStyle: .gray)
    
    @IBOutlet weak var frequencyPeriod: UISegmentedControl!
    @IBOutlet weak var daySelector: UISegmentedControl!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    func markBusy() {
        activityIndicator.startAnimating()
    }
    
    func markStandby() {
        activityIndicator.stopAnimating()
    }
    
    func schedulingUI(enable: Bool) {
        datePicker.isEnabled = enable
        daySelector.isEnabled = enable
    }
    
    @IBAction func dismissSelf() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func segmentValueChanged(_ sender: UISegmentedControl) {
        
        // Instant, Weekly, Monthly
        if sender.tag == 1 {
            schedulingUI(enable: sender.selectedSegmentIndex != 0)
        }
    }
    
    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
        
        guard let selected = tableView.indexPathForSelectedRow, selected.section == 1 else { return }
        // Request Schedule Type
        if selected.row == 0 {
            startDate = sender.date
        }
        else {
            endDate = sender.date
        }
        
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = task.instrument?.sm_title
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        let activityItem = UIBarButtonItem(customView: activityIndicator)
        navigationItem.leftBarButtonItem = activityItem
        tableView.reloadData()
        startDate = Date()
        endDate = Date()
    }
    
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
            
            if indexPath.row == 0 {
                // Start Date
                datePicker.setDate(startDate, animated: true)
                
            }
            else {
                // end date
                datePicker.setDate(endDate, animated: true)
            }
            
            
        }
    }
    
    override func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.detailTextLabel?.textColor = UIColor.darkText
        datePicker.isEnabled = false
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.detailTextLabel?.textColor = UIColor.red
        datePicker.isEnabled = true
        return indexPath
    }
    
    @IBAction func createRequestAction(_ sender: Any) {
        
        guard let patient = fhir.patient else { return }
        markBusy()

        let practitioner = fhir.userProfileSet as? Practitioner
        let instant = (frequencyPeriod.selectedSegmentIndex == 0)
        let weekly  = (frequencyPeriod.selectedSegmentIndex == 1)

        let callback: ((_ request: Request?, _ error: Error?) -> Void) = { [weak self] (req, err) in
            DispatchQueue.main.async {
                if req != nil {
                    self?.sm_showMsg(msg: "Request Created with ID \(req!.id!.string)")
                }
                else {
                    self?.sm_showMsg(msg: "Error encountered when dispatching request.")
                }
                self?.markStandby()
            }
        }

        if instant {
            task.createRequest(on: fhir.mainServer, for: patient, from: practitioner, callback: callback)
        }
            
        else {
            let periodUnit = weekly ? "wk" : "mo"
            let freq = TaskSchedule.Frequency(times: 1, periodType: periodUnit, numberOfPeriods: 1.0)
            let schedule = TaskSchedule(start: startDate, end: endDate, frequency: freq)
            task.createRequest(of: ServiceRequest.self, on: fhir.main.server, for: patient, from: practitioner, schedule: schedule, callback: callback)
        }
    }
}
