//
//  VideoProcessingModels.swift
//  NewFannerCam
//
//  Created by Jin on 2/19/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

struct EventPosition {
    //Intro video
    var rtLogo1         : CGRect!
    var rtLogo2         : CGRect!
    var rtTeam1         : CGRect!
    var rtTeam2         : CGRect!
    var rtEvent1        : CGRect!
    // Period
    var rtEvent2        : CGRect!
}

struct Square {
    var width       : Float = 0.0
    var height      : Float = 0.0
    var x           : Float = 0.0
    var y           : Float = 0.0
}

struct Grid {
    var square                      : Square!
    var numHorizontalSquares        : Int
    var numVerticalSquares          : Int
    var gridHeight                  : Float
    var gridWidth                   : Float
    var squares                     = [Square]()
    
    init(_ width: Float, _ height: Float, _ horiSquares: Int, _ vertSquares: Int) {
        gridWidth = width
        gridHeight = height
        numHorizontalSquares = horiSquares
        numVerticalSquares = vertSquares
        
        splitedGrid()
    }
    
    mutating func splitedGrid() {
        var x = 0
        var y = 0
        
        for  _ in 0..<numHorizontalSquares {
            for _ in 0..<numVerticalSquares {
                var current = Square()
                current.width = gridWidth / (Float)(numHorizontalSquares)
                current.height = gridHeight / (Float)(numVerticalSquares)
                current.x = (Float)(x) * current.width
                current.y = (Float)(y) * current.height
                
                squares.append(current)
                x += 1
            }
            x = 0
            y += 1
        }
        
    }
}

struct ScoreboardPosition {
    var rect                        : CGRect!
    var rtLogo1                     : CGRect! // Logo 1
    var rtLogo2                     : CGRect! // Logo 2
    var rtName1                     : CGRect!
    var rtName2                     : CGRect!
    var rtScore1                    : CGRect!
    var rtScore2                    : CGRect!
    var rtSign                      : CGRect!
}
