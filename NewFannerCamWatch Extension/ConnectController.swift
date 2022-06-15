//
//  ConnectController.swift
//  NewFannerCamWatch Extension
//
//  Created by IE01 on 27/05/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

#if !os(iOS)
import WatchKit
#endif
import Foundation
import WatchConnectivity

class ConnectController: WKInterfaceController
{
    @IBOutlet var labelTitle: WKInterfaceLabel!
    @IBOutlet var buttonConnect: WKInterfaceButton!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
    }

    override func willActivate() {
        super.willActivate()
      //  let watchDeviceName = WKInterfaceDevice.current().name
          let deviceName = UserDefaults.standard.object(forKey: "DeviceName") as? String
          labelTitle.setText(deviceName)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func buttonConnectAction() {
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "RecordingController", context: [:] as AnyObject), (name:"GenericMarkerController", context: [:] as AnyObject), (name:"CollectiveMarkerController", context: [:] as AnyObject)])

       // WKInterfaceController.reloadRootControllers(withNames: ["RecordingController", "GenericMarkerController", "CollectiveMarkerController"], contexts: [])
    }
}
