//
//  Soundtrack.swift
//  NewFannerCam
//
//  Created by Cat on 2/28/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation

struct Recap: Codable {
    
    var recapId                              : Int!
    var recapTitle                           : String!
   
    
    enum RecapKeys : String, CodingKey {
        case recapId                           = "Recap_recapId"
        case recapTitle                        = "Recap_recapTitle"
    }
    
    //MARK: - Init functions
    init(){ }
    
    init(_ jsonData: CustomJSON?) {
        recapId                               = jsonData?["recapId"] as? Int
        recapTitle                            = jsonData?["recapTitle"] as? String
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RecapKeys.self)
        
        recapId                              = try container.decode(Int.self, forKey: .recapId)
        recapTitle                           = try container.decode(String.self, forKey: .recapTitle)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RecapKeys.self)
        
        try container.encode(recapId, forKey: .recapId)
        try container.encode(recapTitle, forKey: .recapTitle)
    }
}
