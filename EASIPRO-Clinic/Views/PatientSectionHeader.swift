//
//  PatientSectionHeader.swift
//  EASIPRO-iPad
//
//  Created by Raheel Sayeed on 26/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import UIKit
import SMART
import SMARTMarkers

class PatientSectionHeader: UITableViewHeaderFooterView {
    
    public weak var baseViewController: UIViewController?
    @IBOutlet weak var btnMeasures: RoundedButton!
    @IBOutlet weak var btnPatient: UIButton!
    @IBOutlet weak var dobLbl: UILabel!
    @IBOutlet weak var mrnLbl: UILabel!
    @IBOutlet weak var btnSession: RoundedButton!
	@IBOutlet weak var btnHistory: RoundedButton!
    @IBOutlet weak var btnHealth: RoundedButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        btnPatient.isEnabled = true
		btnPatient.setTitle("select patient ▼", for: .normal)
        enableControls(shouldEnable: true)
    }
	
	
	public func enableControls(shouldEnable: Bool = true) {
		btnMeasures.isEnabled = shouldEnable
		btnHistory.isEnabled  = shouldEnable
		btnSession.isEnabled = shouldEnable
        btnHealth.isEnabled = shouldEnable
	}
	
	
	public func setPatient(patient: Patient?) {
		
		guard let patient = patient else {
			enableControls(shouldEnable: false)
			btnPatient.setTitle("select patient ▼", for: .normal)
			dobLbl.text = ""
			mrnLbl.text = ""
			return
		}
		
		let pName = patient.humanName ?? "..."
		let patientName = "Patient: \(pName)  ▼"
		btnPatient.setTitle(patientName, for: .normal)
		let gender = patient.gender?.rawValue ?? "..."
		dobLbl.text = "GEN: \(gender)   DOB:   \(patient.humanBirthDateMedium ?? "...")"
		mrnLbl.text = patient.ep_MRNumber()
		enableControls()
	}
}
