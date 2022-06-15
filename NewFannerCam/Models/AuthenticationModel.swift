//
//  AuthenticationModel.swift
//  NewFannerCam
//
//  Created by Jin on 2/18/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation
import Alamofire

struct Authentication {
    var username        : String
    var password        : String
    
    init(_ name: String, _ pwd: String) {
        username = name
        password = pwd
    }
    
    var parameters: Parameters {
        return [
            "username"              : username,
            "password"              : password,
            "device_params"         : [
                "id"            : Utiles.getUniqueDeviceID(),
                "name"          : Utiles.getDeviceName(),
                "type"          : Utiles.getDeviceModel(),
                "os"            : Utiles.getDeviceOS()
            ]
        ]
    }
}
