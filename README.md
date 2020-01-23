EASI-PRO Clinic App
================

### A Clinic app for Patient Generated Health Data including patient-reported outcomes (PROs), adaptive questionnaires, sensor based activity data

EASI-PRO Clinic is a standalone practitioner used iPad(iOS) app designed for use in the hospitals and clinics. It is built on the [SMART on FHIR][sf] open specification and powered by the [SMART Markers][sm] framework to dispatch PGHD requests to patients through the health care context. Built using Swift for iOS.

### PGHD Requests

The app relies on the SMART Markers framework's `Request` protocol to dispatch a FHIR `ServiceRequest` embedded with the relevant PGHD instrument metadata– (reference to a FHIR `Questionnaire` or a ontological code identifying the instrument/data type). The list of available surveys are fetched from the linked FHIR server. Additionally, the [PROMIS][promis] CAT surveys are pulled from its adaptive service provider via its FHIR API. 


Functionality
-------------

1. Practitioners login to their SMART enabled health system.
2. Fetch all available [PGHD Instruments][ilist] from the FHIR server.
3. Dispatch requests for the selected instrument; optionally associated with a schedule.
4. Optionally, PGHD sessions can be administered right on the tablet device. 

Configuration
------------

1. You will need Xcode version 11.3 and Swift 5.0 and a `FHIR Server` endpoints and optionally their SMART credentials.
1. Clone repository: `$ git clone --recursive https://github.com/smartmarkers/easipro-clinic-pghd-ios`
2. Make sure SMARTMarkers and its submodules are downloaded
1. Add SMARTMarkers.xcodeproj, ResearchKit.xcodeproj, SMART.xcodeproj to the application's project workspace
4. Compile ResearchKit and SMARTMarkers.xcodeproj
5. Go to Project Settings -> General Tab and add the three frameworks and HealthKit to the `Frameworks, Libraries, and Embedded Content`.
6. Build and run the app


You will need a SMART on FHIR endpoint to get started
```swift
extension FHIRManager {

    /**
     SMART Sandbox Credentials take from Config.xcconfig via App's
     - REPLACE Settings or create a new Client for other FHIR Servers
     */
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
            "client_id"     : "easipro-clinic-id",
            "redirect"      : "smartmarkers-home://smartcallback",
            "scope"         : "openid profile user/*.* launch"
        ]
        let smart_baseURL = URL(string: baseURI)!
        let client = Client(baseURL: smart_baseURL, settings: settings)
        client.authProperties.granularity = .tokenOnly

        //Initalize PROMIS FHIR server client with base uri, id, secret
        let promis = PROMISClient(..)
        return FHIRManager(main: client, promis: promis)
    }
}

  /*
  Initialize FHIRManager
  Can be done in AppDelegate
  */

lazy var fhir: FHIRManager! = {
        return FHIRManager.SMARTSandbox()
    }()


// Catch callback for SMART authorization
func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {

        if fhir.main.awaitingAuthCallback {
            return fhir.main.didRedirect(to: url)
        }

        return false
    }
```

SMART Markers
-------------
This app was built on top of the SMART Markers framework but with its own custom interface and user experience designed specifically for PROMIS instruments and has now expanded to include various instruments enabled by the framework. [ResearchKit][rk] and [SwiftSMART][sw] are used as its submodules. 


[sm]: https://github.com/smartmarkers/smartmarkers-ios
[sf]: https://docs.smarthealthit.org
[promis]: https://healthmeasures.net
[ilist]: https://github.com/SMARTMarkers/smartmarkers-ios/tree/master/Sources/Instruments
[rk]: https://researchkit.org
[sw]: https://github.com/smart-on-fhir/Swift-SMART


