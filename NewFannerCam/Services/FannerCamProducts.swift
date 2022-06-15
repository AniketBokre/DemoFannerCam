//
//  FannerCamProducts.swift
//  NewFannerCam
//
//  Created by Jin on 2/25/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation

public struct FannerCamProducts {
    
    // Consumable
    public static let FiveMatch = "com.FannerCamItaly.5Matches"
    public static let FiftyMatch = "com.FannerCamItaly.50Matches"
    public static let OFiftyMatch = "com.FannerCamItaly.150Matches"
    
    private static let matches: Set<ProductIdentifier> = [FiveMatch, FiftyMatch, OFiftyMatch]
    
    public static let matchStores = IAPService(productIds: matches)
    
    // Soundtrack
    public static let Music = "com.fanner.fannerApp.monthly.musicSoundtrack"
    public static let Anthem = "com.fanner.fannerApp.Monthly.anthemSoundtrack"
    
    private static let soundtracks: Set<ProductIdentifier> = [Anthem, Music]
    
    public static let soundtrackStore = IAPService(productIds: soundtracks)
    
    // Template
    public static let Base = "com.fanner.fannerApp.monthly.baseTemplate"
    public static let Custom = "com.fanner.fannerApp.monthly.customTemplate"
    
    private static let templates : Set<ProductIdentifier> = [Base, Custom]
    
    public static let templatesStore = IAPService(productIds: templates)
    
}

func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
    return productIdentifier.components(separatedBy: ".").last
}
