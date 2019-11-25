//
//  MainViex`wController.swift
//  EASIPRO-Clinic
//
//  Created by Raheel Sayeed on 5/3/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import UIKit
import SMARTMarkers
import SMART
import ResearchKit

class MainViewController: UITableViewController {
    
    // Get fhir manager from the appDelegate
    var fhir: FHIRManager! = (UIApplication.shared.delegate as! AppDelegate).fhir
    
    /// PROMIS Instruments List
    let promisListView = PROMISListViewController(client: PROMISClient.New())

    /// Session Controller to administer Patient Generating Tasks
    var sessionController : SessionController?
    
    /// Array for tasks
    var tasks = [TaskController]()
    
    /// Begin Session
    weak final var btnBeginSession : RoundedButton?
    
    
    var status : String = "" {
		didSet {
            DispatchQueue.main.async { [weak self] in
				self?.statusLabel?.text = self?.status
			}
		}
    }
    
    weak var patientHeaderView: PatientSectionHeader?
    
    var statusLabel : UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Clinic"
        navigationItem.largeTitleDisplayMode = .automatic
        let nib = UINib(nibName: "PatientSectionHeader", bundle: nil)
        let nibFooter = UINib(nibName: "SessionActionView", bundle: nil)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: "PatientSectionHeader")
        tableView.register(nibFooter, forHeaderFooterViewReuseIdentifier: "SessionActionView")
        tableView.separatorStyle = .singleLine
        setupUI()
        configureCallbacks()
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PROMCell", for: indexPath)
        let task = tasks[indexPath.row]
        if task.instrument == nil { fatalError("TaskController needs Instrument!") }
        cell.textLabel?.text = "\(indexPath.row+1): \(task.instrument!.sm_title)"
        cell.tag = indexPath.row
        
        if task.reports?.hasReportsForToday() ?? false {
            cell.accessoryView = MainViewController.self.GreenCheckmarkAccessoryView()
        }
        else {
            cell.accessoryType = .detailButton
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        patientHeaderView = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: "PatientSectionHeader") as? PatientSectionHeader
        patientHeaderView?.baseViewController = self
        patientHeaderView?.btnMeasures.addTarget(self, action: #selector(selectPROMISCAT(_:)), for: .touchUpInside)
        patientHeaderView?.btnPatient.addTarget(self, action: #selector(selectPatient(_:)), for: .touchUpInside)
        patientHeaderView?.btnSession.addTarget(self, action: #selector(selectSurveys(_:)), for: .touchUpInside)
        patientHeaderView?.btnHistory.addTarget(self, action: #selector(selectActiveMeasures(_:)), for: .touchUpInside)
        return patientHeaderView
    }
    
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let cell = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: "SessionActionView") as! SessionActionView
        cell.btnStart.addTarget(self, action: #selector(beginSession(_:)), for: .touchUpInside)
        btnBeginSession = cell.btnStart
        return cell
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 220
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return tasks.count > 0 ? 120 : 0
    }
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsetsMake(0, 100, 0, 100)
        cell.separatorInset = UIEdgeInsetsMake(0, 100, 0, 100)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        guard let report = tasks[indexPath.row].reports?.reports.last else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let viewController: UIViewController
        if let response = report as? QuestionnaireResponse {
            viewController = QuestionnaireResponseViewController(response)
        }
        else {
            viewController = ReportViewController(report)
        }
        let nav = UINavigationController(rootViewController: viewController)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true, completion: nil)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "scheduleView", let scheduler = (segue.destination as? UINavigationController)?.topViewController as? RequestOrderViewController {
            scheduler.task = tasks[(sender as! UITableViewCell).tag]
            scheduler.patient = fhir.patient
            scheduler.practitioner = fhir.userProfileSet as? Practitioner
            scheduler.server = fhir.main.server
        }
        
        super.prepare(for: segue, sender: sender)
    }
    
    
    func showMsg(msg: String) {
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        let alertViewController = UIAlertController(title: "Clinic", message: msg, preferredStyle: .alert)
        alertViewController.addAction(alertAction)
        present(alertViewController, animated: true, completion: nil)
    }
	
	
    func setupUI() {
		
		let formatter = DateFormatter()
		formatter.dateStyle = .full
		formatter.timeStyle = .none
        let profileBtn = UIBarButtonItem(image: UIImage.init(named: "profileicon"), style: .plain, target: self, action: #selector(showProfile))
        let practitionerBtn = UIBarButtonItem(title: "LOGIN", style: .plain, target: self, action: #selector(showProfile))
        navigationItem.rightBarButtonItems = [profileBtn, practitionerBtn]
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: formatter.string(from: Date()), style: .plain, target: nil, action: nil)
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let clearMeasuresItem = UIBarButtonItem(title: "Reset Instruments", style: .plain, target: self, action: #selector(resetInstruments))
		let proHistory = UIBarButtonItem(title: "History", style: .plain, target: self, action: #selector(showPROHistory(_:)))
        statusLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 40))
        statusLabel?.text = "Ready"
        statusLabel?.textAlignment = .center
		statusLabel?.textColor = .white
		statusLabel?.font = UIFont(descriptor: .preferredFontDescriptor(withTextStyle: .title3), size: 15)
        let labelItem = UIBarButtonItem(customView: statusLabel!)
        toolbarItems = [clearMeasuresItem, flexibleItem, labelItem, flexibleItem, proHistory]
        
        
    }
    
    func configureCallbacks() {
        
        fhir.onPatientSet = { [unowned self] in
            DispatchQueue.main.async {
                self.patientHeaderView?.setPatient(patient: self.fhir.patient)
            }
        }
        
        fhir.onProfileSet = { [unowned self] in
            if let practitioner = self.fhir.userProfileSet as? Practitioner {
                DispatchQueue.main.async {
                    let name = practitioner.name?.first?.human ?? " ---> "
                    let practitionerBarItem = self.navigationItem.rightBarButtonItems![1]
                    practitionerBarItem.title = name
                }
            }
        }
    }
    static func GreenCheckmarkAccessoryView() -> UIButton {
        let btn = UIButton(type: .roundedRect)
        let img = UIImage.init(named: "greencheckmark")
        let imgView = UIImageView(image: img)
        imgView.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        btn.setBackgroundImage(img, for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
        btn.contentMode = .center
        return btn
    }
    
    
    
    @objc func showPROHistory(_ sender: Any) {
        let insights = InsightsController(style: .grouped)
        insights.view.backgroundColor = view.backgroundColor
        let navigationController = UINavigationController(rootViewController: insights)
		navigationController.navigationBar.barStyle = .black
        self.present(navigationController, animated: true, completion: nil)
    }
    
    @objc func selectPatient(_ sender: Any) {
        fhir.showPatientSelector()
    }
    
    @objc func resetInstruments() {
        tasks.removeAll()
        tableView.reloadData()
    }
    
    @objc func showProfile() {
        
        fhir.authorize { [weak self] (success, userName, error) in
            DispatchQueue.main.async {
                if let userName = userName {
                    self?.statusLabel?.text = "Logged in as \(userName)"
                }
                else if success {
                    self?.statusLabel?.text = "Authorization complete"
                }
                else {
                    if let error = error {
                        self?.statusLabel?.text = "Some error occurred authorizing"
                        self?.showMsg(msg: "Authorization Failed.\n\(error.asOAuth2Error.localizedDescription)")
                    }
                }
            }
            
        }
    }
    
    
    
    
    // MARK: AC Session Management
    
    @objc public func beginSession(_ sender: Any?) {
        
        let practitioner = fhir.userProfileSet as? Practitioner
        
        guard let patient = fhir.patient, tasks.count > 0 else {
            showMsg(msg: "Please login, select a patient and an instrument")
            return
        }
        let server = fhir.main.server
        
        let btn = sender as? RoundedButton ?? nil
        btn?.busy()
        
        sessionController = SessionController(tasks, patient: patient, server: server, verifyUser: false)

        sessionController?.prepareController(callback: { [weak self] (viewController, error) in
            
            guard let viewController = viewController else {
                self?.showMsg(msg: "A Session could not be created")
                btn?.reset()
                return
            }
            viewController.view.tintColor = UIColor.red
            DispatchQueue.main.async {
                self?.present(viewController, animated: true, completion: nil)
            }
        })
        
        sessionController?.onConclusion = { [weak self] session in
            self?.resetOnMainQueue()
        }
    }
    
    func resetOnMainQueue() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.btnBeginSession?.reset()
            self.btnBeginSession?.isEnabled = self.tasks.count > 0
        }
    }
}

extension MainViewController : UIPopoverPresentationControllerDelegate{
	
	func popUpNavigationController(root: UIViewController, frame:CGRect) -> UINavigationController {
		let navigationController = UINavigationController(rootViewController: root)
		navigationController.modalPresentationStyle = UIModalPresentationStyle.popover
		navigationController.popoverPresentationController?.sourceView = self.view
		navigationController.popoverPresentationController?.sourceRect = frame
		navigationController.popoverPresentationController?.delegate = self
		return navigationController
	}
	
	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
		return .none
	}
}




