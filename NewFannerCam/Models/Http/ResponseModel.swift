//
//  ResponseModel.swift
//  NewFannerCam
//
//  Created by Cat on 2/18/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation

typealias CustomJSON = [String: Any]

public struct Response {
    
    var response    : CustomJSON?
    var success     : Bool = false
    var message     : String!
    var code        : Int = 0
    
    init() {
        
    }
    
    init(_ value: CustomJSON) {
        success = value["success"] as! Bool
        if let codeStr = value["code"] as? String {
            code = Int(codeStr) ?? 0
        }
        message = value["message"] as? String
        response = value["response"] as? CustomJSON
    }
    
    var templates   : [Template] {
        let items = response?["items"] as? NSArray
        var result = [Template]()
        items?.forEach{ item in
            let jsonData = item as? CustomJSON
            result.append(Template(jsonData))
        }
        return result
    }
    
    var soundtracks : [Soundtrack] {
        let items = response?["items"] as? NSArray
        var result = [Soundtrack]()
        items?.forEach{ item in
            let jsonData = item as? CustomJSON
            result.append(Soundtrack(jsonData))
        }
        return result
    }
}
