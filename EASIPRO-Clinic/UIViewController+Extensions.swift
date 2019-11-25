//
//  UIViewController+Extensions.swift
//  EASIPRO-Clinic
//
//  Created by Raheel Sayeed on 11/25/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func sm_showMsg(msg: String) {
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        let alertViewController = UIAlertController(title: "SMART Markers", message: msg, preferredStyle: .alert)
        alertViewController.addAction(alertAction)
        present(alertViewController, animated: true, completion: nil)
    }
}
