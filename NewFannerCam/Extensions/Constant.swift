//
//  Constants.swift
//  NewFannerCam
//
//  Created by Jin on 12/27/18.
//  Copyright © 2018 fannercam3. All rights reserved.
//

import UIKit
import Foundation

let EMPTY_STRING                        = "EMPTY_STRING"
let APP_NAME                            = "Fanner Cam"

let kEXTERNALREGISTRATIONURL            = "https://fannercam.it/registration"
let TEMPLATE_JSON                       = "https://d1a543h7yz12to.cloudfront.net/api/video_templates.json"
let SOUNDTRACK_JSON                     = "https://d1a543h7yz12to.cloudfront.net/api/video_soundtracks.json"
let grayTrackImage                      = ImageProcess.image(solidColor: .gray, size: CGSize(width: 30, height: 30))

struct Constant {
    
    struct Color {
        static let red                      = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
        static let blue                     = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        static let black                    = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        static let defaultBlack             = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
        static let white                    = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        static let yellow                   = #colorLiteral(red: 0.9994240403, green: 0.9855536819, blue: 0, alpha: 1)
        static let clear                    = UIColor.clear
    }
    
    struct ObserverKey {
        static let Captured                 = "captured"
    }
    
    enum Image: String {
        case RecordMatch                    = "ic_create_record_match_white"
        case ImportMatch                    = "ic_create_import_match_white"
        case ToggleStop                     = "ic_record_stop_red"
        case ToggleRecord                   = "ic_record_red"
        case CheckMarkWhite                 = "check_white"
        case UncheckMarkWhite               = "uncheck_white"
        case PlayWhite                      = "ic_play_white"
        case PauseWhite                     = "ic_pause_white"
        case DefaultTeamLogo                = "default_team_logo.png"
        case FannerLogo                     = "fanner_logo.png"
        case BannerReplay                   = "banner_replay.png"
        case AddBlack                       = "ic_add_black"
        case AddWhite                       = "ic_add_white"
        case DeleteWhite                    = "ic_delete_white"
        
        var image                           : UIImage? {
            return UIImage(named: self.rawValue)
        }
    }
    
    struct Cell {
        static let MatchCellId              = "MatchCell"
        static let MatchMainVideoCellId     = "MatchesDetailMainVideoCell"
        static let MatchClipCellId          = "MatchesHighlightsCell"
        static let MatchDetailClipDropCell  = "MatchesDetailHighlightDropDownCell"
        static let SettingCell              = "SettingsCell"
        static let SettingsMarkersCell      = "SettingsMarkersCell"
        static let SettingsMarkerDropCell   = "SettingsMarkersDetailDropDownCell"
    }
    
    struct Segue {
        static let MatchesHighlightsSegueId         = "MatchesHighlightsSegue"
        static let MatchesReportSegueId             = "MatchesDetailReportSegue"
        static let MatchesRecordSegueId             = "MatchesMainVideoRecordSegue"
        static let MatchesRecordSegueIdLive             = "MatchesMainVideoRecordSegueLive"
        static let MatchesVideoPlaySegueId          = "MatchesMainVidePlaySegue"
        static let MatchesDetailClipInfoSegueId     = "MatchesDetailClipInfoSegue"
        static let MatchRecoverySegueId             = "RecoveryVCSegue"
        static let VideoPlaySegueId                 = "VideoPlayerSegue"
        static let VideoStopframeEditSegueId        = "StopFrameEditSegue"
        static let SettingMarkerSegueId             = "SettingsMarkersSegue"
        static let SettingsTemTraSegueId            = "SettingsTemTraSegue"
        static let SettingsYoutubeSegueId           = "SettingsYoutubeSegue"
        static let SettingsSubscriptionSegueId      = "SettingsSubscriptionsSegue"
        static let SettingImgArchiveSeugueId        = "SettingsImgArchiveSegue"
        static let SettingImgArchiveSeugueId2        = "SettingsImgArchiveSegue2"
        static let SettingsMarkersDetailSegueId     = "SettingsMarkersDetailSegue"
        static let SettingsLoginLiverecapSegueId     = "SettingsLoginLiverecapSegue"
        static let SettingsLiverecapProfileSegueId     = "SettingsLiverecapProfile"
        
    }
    
    struct Storyboard {
        static let Main                     = "Main"
        static let Vidoes                   = "Videos"
        static let Setting                  = "Settings"
        static let Matches                  = "Matches"
    }
    
    struct StoryboardIds {
        static let CreateMatchNvc           = "CreateNewMatchNVC"
        static let MainVideo                = "MainVideo"
        static let MatchMainVideoPlayVC     = "MatchMainVideoPlayVC"
        static let MatchRecoveryVC          = "MatchRecoveryVC"
        static let ScoreSettingVC           = "MatchesScoreSettingVC"
        static let Highlights               = "Highlights"
        static let AppLibNavController      = "AppLibNavController"
        static let VideoPlayerVC            = "VideoPlayerVC"
        static let SettingsSubscriptionsNVC = "SettingsSubscriptionsNVC"
        static let SettingsTemTraNav        = "SettingsTemTraNav"
        static let TermPrivacyWebVC         = "TermPrivacyWebVC"
        static let StorePurchaseVC          = "StorePurchaseVC"
        static let RecapListVC          = "RecapListVC"
    }
    
    enum ViewControllerType {
        case Privacy
        case Terms
        case EULA
    }
    
}

func getServerBaseUrl()-> String {

    var myDict: NSDictionary?
    
    if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
        myDict = NSDictionary(contentsOfFile: path)
    }
    
    if let dict = myDict {
        
    return (dict["StagingServerBaseURL"] as! String)
        
    }
    return ""
}

func getLoginURL()-> String {
    return "authentication/login"
}

func getRecapListURL()-> String {
    return "recap/customerList/"
}

func getLiveRecapListURL()-> String {
    return "recap/listRecapsLive/"
}

func getCreateClipURL()-> String {
    return "clip/create"
}
