//
//  Marker.swift
//  NewFannerCam
//
//  Created by Jin on 1/15/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation

enum MarkerType: String {
    case individual             = "Individual"
    case generic                = "Generic"
    case collective             = "Collective"
    
    var actionImage : ActionImage {
        switch self {
        case .individual:
            return ActionImage.individual
        case .generic:
            return ActionImage.generic
        case .collective:
            return ActionImage.collective
        }
    }
}

struct Marker: Codable {
    
    var id                      : String!
    var name                    : String!
    var type                    = MarkerType.individual
    var duration                : Float64!
    
    enum MarkerKeys : String, CodingKey {
        case id                 = "Marker_id"
        case name               = "Marker_name"
        case type               = "Marker_type"
        case duration           = "Marker_duration"
    }
    
//MARK: - Main functions
    func titleDescription() -> String {
        return name ?? String()
    }
    
    func durationDescription() -> String {
        return "\(Int(duration))\""
    }
    
    mutating func set(_ duration: Float64) {
        self.duration = duration
    }
    
//MARK: - Init functions
    init(_ id: String, _ name: String, _ type: MarkerType, _ duration: Float64) {
        self.id = id
        self.name = name
        self.type = type
        self.duration = duration
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MarkerKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let typeStr = try container.decode(String.self, forKey: .type)
        type = MarkerType(rawValue: typeStr) ?? MarkerType.individual
        duration = try container.decode(Float64.self, forKey: .duration)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MarkerKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(duration, forKey: .duration)
    }
    
}
