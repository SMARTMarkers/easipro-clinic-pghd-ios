//
//  EP+ACConfig.swift
//  EASIPRO-Clinic
//
//  Created by Raheel Sayeed on 03/05/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMARTMarkers
import SMART

/*
 - Settings for FHIR Server
 - Config.xcconfig has all the config settings for a sample FHIR Server
 - Configuration settings file format documentation can be found at:
 - https://help.apple.com/xcode/#/dev745c5c974
 
 ******
 Replace URLs with your own settings for a FHIR server
 ******
 */

extension FHIRManager {
    
    class func SMARTSandbox() -> FHIRManager {
        
        let infoDict = Bundle.main.infoDictionary!
        guard var baseURI = infoDict["FHIR_BASE_URL"] as? String else {
            fatalError("Need FHIR Endpoint")
        }
        if !baseURI.hasPrefix("http") {
            baseURI = "https://" + baseURI
        }
        
        let settings = [
            "client_name"   : "easipro-clinic",
            "client_id"     : "app-client-id",
            "redirect"      : "smartmarkers-clinic://smartcallback",
            "scope"         : "openid profile user/*.* launch"
        ]
        let smart_baseURL = URL(string: baseURI)!
        let client = Client(baseURL: smart_baseURL, settings: settings)
        client.authProperties.granularity = .launchContext
        return FHIRManager(main: client, promis: PROMISClient.New())
        
    }
}




/**
 AssessmentCenter's Credentials taken from Config.xcconfig via App's Info.plist
 - REPLACE Credentials with your own
 */
extension PROMISClient {

    public class func New() -> PROMISClient {
        
        let infoDict = Bundle.main.infoDictionary!
        guard var baseURI = infoDict["ASSESSMENTCENTER_BASE_URL"] as? String else {
            fatalError("Need PROMIS AssessmentCenter Endpoint")
        }
        
        if !baseURI.hasPrefix("http") {
            baseURI = "https://" + baseURI
        }
        
        return PROMISClient(baseURL: URL(string: baseURI)!,
                            client_id: infoDict["ASSESSMENTCENTER_ACCESSID"] as! String,
                            client_secret: infoDict["ASSESSMENTCENTER_ACCESSTOKEN"] as! String)
    }
}

