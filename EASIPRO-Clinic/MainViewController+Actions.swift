//
//  MainView+Lists.swift
//  EASIPRO-Clinic
//
//  Created by Raheel Sayeed on 11/24/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMARTMarkers


extension MainViewController {
    
    @objc public func selectPROMISCAT(_ sender: RoundedButton) {
        
        promisListView.onSelection = { _instruments in
            if let _instruments = _instruments {
                self.tasks.append(contentsOf: _instruments.map ({ TaskController(instrument: $0) }))
            }
            self.resetOnMainQueue()
        }
        present(popUpNavigationController(root: promisListView, frame: sender.frame), animated: true, completion: nil)
    }
    
    @objc public func selectSurveys(_ sender: RoundedButton) {
        
        let measuresViewController = InstrumentListViewController(server: fhir.mainServer)
        measuresViewController.onSelection = { _instruments in
            if let _instruments = _instruments {
                self.tasks.append(contentsOf: _instruments.map ({ TaskController(instrument: $0) }))
            }
            self.resetOnMainQueue()
        }
        present(popUpNavigationController(root: measuresViewController, frame: sender.frame), animated: true, completion: nil)
    }
    
    @objc func selectActiveMeasures(_ sender: UIButton) {
        let activeMeasures = ActiveTaskListViewController()
        activeMeasures.onSelection = { [weak self] (_instruments) in
            if let _instruments = _instruments {
                self?.tasks.append(contentsOf: _instruments.map{ TaskController(instrument: $0) })
            }
            self?.resetOnMainQueue()
        }
        present(popUpNavigationController(root: activeMeasures, frame: sender.frame), animated: true, completion: nil)
        
        
    }
    
    @objc func selectHealthInstruments(_ sender: UIButton) {
        
        let healthList = HealthInstrumentsListViewController(callbackManager: fhir.callbackManager!)
            healthList.onSelection = { [weak self] (_instruments) in
                if let _instruments = _instruments {
                    self?.tasks.append(contentsOf: _instruments.map{ TaskController(instrument: $0) })
                }
                self?.resetOnMainQueue()
            }
            present(popUpNavigationController(root: healthList, frame: sender.frame), animated: true, completion: nil)
            
        }
    
}


public class HealthInstrumentsListViewController: InstrumentListViewController {
    
    var callback: CallbackManager!
            
    public convenience init(callbackManager: CallbackManager) {
        self.init(server: nil)
        callback = callbackManager
    }
    
    open override func loadQuestionnaires() {
        if nil != instruments { return }
        title = "Active Tasks"
        markBusy()
        set([
            Instruments.HealthKit.StepCount.instance,
            Instruments.Web.OmronBloodPressure.instance(authSettings: [:], callbackManager: &callback)
        ])
        markStandby()
    }
}
